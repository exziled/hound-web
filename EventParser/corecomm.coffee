dgram = require('dgram')
json_sanitizer = require('json_sanitizer')

delay = (ms, func) -> setTimeout func, ms

class CoreComm

	constructor: (@settings) ->
		@event_map = {}
		@core_map = {}

		@counter = 0;
		server = dgram.createSocket('udp4');
		server.bind @settings.listen_udp_port, ()=>
			server.addMembership(@settings.udp_multicast)
			console.info("UDP Multicast listening on ip %s",@settings.udp_multicast)

		server.on "error", (err) =>
			console.error("server error:\n" + err.stack)
			server.close()


		server.on "listening", () =>
			address = server.address();
			console.info("UDP server listening on port " + address.port)

		server.on "message",  (data, rinfo) =>
			data = ""+data; #convert the buffer to a string
			data = data.replace(/\0/,''); #@todo shouldn't need this

			json_sanitizer data, (err, result) =>
				if (!err)
					msg = JSON.parse(result)
					# console.log(msg); #debug.printAllincommingUDPmessages

					if (!msg.hasOwnProperty('e'))
						console.log("msg does not have an e property", msg)
						return;

					if (msg.hasOwnProperty('core_id'))
						@core_map[msg.core_id] = rinfo.address #update the core_map
						console.log("core_map Updated %s = %s", msg.core_id, rinfo.address)

					handlers = @event_map[msg.e]
					if handlers == undefined
						console.log("no handlers defined for", msg.e, msg)
						return

					for handler in handlers
						handler(null, msg, rinfo) #callbacks must be in the format err, data
				else
					console.log("ERROR", err, result, data)

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
	send: (buff, core_id, retrycount, callback) ->

		if typeof retrycount == 'function'
			callback = retrycount
			retrycount = 0

		ip = core_id
		if not (/^(?!0)(?!.*\.$)((1?\d?\d|25[0-5]|2[0-4]\d)(\.|$)){4}$/.test(core_id)) #not is_ip
			if @core_map[core_id] == undefined
				callback("FAIL: Unable to send message. "+core_id+" not registered in core_map",null)
				return;
			else
				ip = @core_map[core_id]

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
			# console.log("Sent: ",out); #debug.printAllOutgoingUDPmessages

			if retrycount >= @settings.max_udp_retry
				callback('UDP Permanently failed sending '+out+' after '+retrycount+' retries', null)
				return

			timeoutID = delay @settings.udp_timeout, ()=>
				retrycount++
				console.error("UDP Timed out", retrycount)
				@off mycnt.toString()
				@send(buff, ip, retrycount, callback)

			@on mycnt.toString(), (err, data) =>
				clearTimeout(timeoutID) #if we get a reply clear the timeout
				callback(err, data)
				@off mycnt.toString()

	# create a data subscripton
	createSub: (ip, callback) ->
		@send 0x2, ip, (err, reply) ->
			console.log("need core_id here", reply); # figure out what this reply.core_id should be to update core_map @todo
			if not err and reply.result == 1
				callback(null, reply) # Subscription created
			else
				callback(err||"Unable to create subscription", reply)

	# destroy a data subscripton
	destroySub: (core_id) ->
		console.log("Its not currently possible to destroy a subscripton")

	#create a subscription with the core for high-speed data
	createFastSub: (core_id) ->
		@send 0x0400, core_id, (err, reply) ->
			if not err and reply.result == 0
				console.info("Fast-Data Subscription Created with", core_id)
				socket.emit('who')
			else
				console.error("%s unable to create websockets subsription", core_id, reply)

	#destroy the subscription for high-speed data
	destroyFastSub: (core_id) ->
		@send 0x0401, @core_map[core_id], (err, reply) ->
			console.info("Fast-Data Subscription Destroyed ",err, reply)

	# set the state of the outlets
	control: (core_id, outlet, state, callback) ->
		top = 0x0100 #top outlet
		bot = 0x0110 #bottom outlet

		if (outlet == "outlet1")
			msg = top
		else if (outlet == "outlet2")
			msg = bot
		else
			console.error("Unknown Outlet ", outlet)
			callback('Unknown Outlet '+outlet, null)
			return;

		if (state == 'on')
			msg |= 0x0001;
			expect = 1
		else if (state == 'off')
			msg |= 0x0000;
			expect = 0
		else
			console.error("Unknown State ", state)
			callback('Unknown State '+state, null)
			return;

		@send msg, core_id, (err, reply) ->
			if not err and reply.result[0].state == expect
				console.log("%s set to %s",outlet, state)
				callback(null, reply)
			else
				console.error("FAIL: could not set %s to %s", outlet, state)
				callback(err||"No state change", reply)

	# get measuement data
	getData: (core_id) ->
		console.log("I don't know how to \"getData\" yet, can you teach me?")

	# read the state of the outlets
	getState: (core_id, callback) ->
		@send 0x010212, core_id, (err, reply) ->
			console.log("reply", err, reply)
			callback(err, reply)

module.exports = CoreComm
