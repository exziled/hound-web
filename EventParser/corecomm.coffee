dgram = require('dgram')
json_sanitizer = require('json_sanitizer')

delay = (ms, func) -> setTimeout func, ms

class CoreComm
	@core_map = {}

	constructor: (@settings) ->
		@event_map = {}

		@counter = 0;
		server = dgram.createSocket('udp4');
		server.bind @settings.listen_udp_port, ()=>
			server.addMembership(@settings.udp_multicast)
			console.info("UDP Multicast listening on ip %s",@settings.udp_multicast);

		server.on "error", (err) =>
			console.error("server error:\n" + err.stack)
			server.close()


		server.on "listening", () =>
			address = server.address();
			console.info("UDP server listening on port " + address.port);
			console.log(""); #add a blank line

		server.on "message",  (data, rinfo) =>
			data = ""+data; #convert the buffer to a string
			data = data.replace(/\0/,''); #@todo shouldn't need this

			json_sanitizer data, (err, result) =>
				if (!err)
					msg = JSON.parse(result)
					# console.log(msg);

					if (!msg.hasOwnProperty('e'))
						console.log("msg does not have an e property", msg);
						return;

					if (!msg.hasOwnProperty('core_id'))
						coremap[msg.core_id] = rinfo.address #update the coremap
						console.log("Coremap Updated %s = %s", msg.core_id, rinfo.address);

					handlers = @event_map[msg.e]
					if handlers == undefined
						console.log("no handlers defined for", msg.e, msg)
						return

					for handler in handlers
						handler(null, msg, rinfo) #callbacks must be in the format err, data
				else
					console.log("ERROR", err, result, data);

	#callbacks must be in the format err, data
	on: (evt, callback) ->
		# console.log("on", evt);
		if (not (evt of @event_map))
			@event_map[evt] = [callback]
		else
			@event_map[evt].push(callback)

	#pass the same callback to remove
	off: (evt, callback) ->
		# console.log("off", evt);
		if (not (evt of @event_map))
			return
		else
			if (@event_map[evt].length == 1) #allow removal with only evtname if its the only handler
				delete @event_map[evt]
				return

			if (callback == undefined)
				console.error("Unable to remove handler", @event_map)
				return

			idx = @event_map[evt].indexOf(callback)
			@event_map[evt].splice(idx, 1) #remove from array

	#callback is in the format (err, data)
	send: (buff, ip, callback) ->
		# pad the buffer to ensure that it is an even number of digits representing
		# a multiple of 8 bits
		out = buff.toString(16) #convert to base 16
		if out.length %2 != 0
			out = "0"+out;

		@counter += 1;
		if @counter >= 255
			@counter = 0;

		mycnt = @counter

		cnt = mycnt.toString(16) #convert to base 16
		if cnt.length %2 != 0
			cnt = "0"+cnt;

		out = cnt+out;

		out1 = new Buffer(out, "hex");
		client = dgram.createSocket("udp4")
		client.send out1, 0, out1.length, @settings.outgoing_udp_port, ip, (err, bytes) =>
			client.close();
			client = null;
			console.log("Sent: ",out);

			timeoutID = delay @settings.udp_timeout, ()=>
				console.log("UDP Timed out");
				@off mycnt.toString()
				@send(buff, ip, callback);

			@on mycnt.toString(), (err, data) =>
				clearTimeout(timeoutID) #if we get a reply clear the timeout
				callback(err, data);
				@off mycnt.toString()

	# create a data subscripton
	createSub: (ip, cb) ->
		@send 0x2, ip, (err, reply) ->
			if not err and reply.result == 1
				console.log("Subscription created with core",data.id)
			else
				console.log("Unable to create subscription")

	# destroy a data subscripton
	destroySub: (core_id) ->
		console.log("Its not currently possible to destroy a subscripton")

	#create a subscription with the core for high-speed data
	createFastSub: (core_id) ->
		@send 0x0400, @coremap[core_id], (err, reply) ->
			if not err and reply.result == 0
				console.info("Fast-Data Subscription Created with", core_id);
				socket.emit('who');
			else
				console.error("%s unable to create websockets subsription", core_id, reply);

	#destroy the subscription for high-speed data
	destroyFastSub: (core_id) ->
		@send 0x0401, @coremap[core_id], (err, reply) ->
			console.info("Fast-Data Subscription Destroyed ",err, reply);

	# set the state of the outlets
	control: (outlet, state, core_id) ->
		top = 0x0100 #top outlet
		bot = 0x0110 #bottom outlet

		if (outlet == "outlet1")
			msg = top
		else if (outlet == "outlet2")
			msg = bot
		else
			console.error("Unknown Outlet ", data.outlet);
			return;

		if (state == 'on')
			msg |= 0x0001;
			expect = 1
		else if (state == 'off')
			msg |= 0x0000;
			expect = 0
		else
			console.error("Unknown State ", data.state);
			return;

		@send msg, @coremap[core_id], (err, reply) ->
			if not err and reply.result[0].state == expect
				console.log("%s set to %s",outlet, state)
			else
				console.error("FAIL: could not set %s to %s", outlet, state);

	# get measuement data
	getData: () ->

	# read the state of the outlets
	getState: (core_id) ->
		@send 0x010212, @coremap[core_id], (err, reply) ->
			console.log("reply", err, reply);

module.exports = UDP_Server
