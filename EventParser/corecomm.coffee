dgram = require('dgram')
json_sanitizer = require('json_sanitizer')
console = require('better-console')

# Let's change the order of the parameters to setTimeout for clairity
delay = (ms, func) -> setTimeout func, ms

# Note: ALL callbacks must be in the format err, data

class CoreComm

	constructor: (@settings) ->

		# Holds the relation between UDP "events" and the callbacks to call when those events occur
		@event_map = {}

		# Holds the relation between cores and their ipaddresses
		# http://stackoverflow.com/questions/518000
		@core_map = {} # {"coreid":"ipaddress"}

		# the message counter, use to identify responses
		@counter = 0;

		server = dgram.createSocket('udp4')

		# listen on udp multicast for broadcasts
		if @settings.listen_udp_port
			server.bind @settings.listen_udp_port, ()=>
				server.addMembership(@settings.udp_multicast)
				console.info("UDP Multicast listening on ip %s",@settings.udp_multicast)

		# triggered on a UDP error
		server.on "error", (err) =>
			console.error("UDP server error:\n" + err.stack)
			server.close()

		# triggered when the UDP server begins listening
		server.on "listening", () =>
			address = server.address();
			console.info("UDP server listening on port " + address.port)

		# triggered when a UDP message is recieved
		server.on "message",  (data, rinfo) =>
			data = ""+data; #convert the buffer to a string
			data = data.replace(/\0/,''); #@todo shouldn't need this

			json_sanitizer data, (err, result) =>
				if (!err)
					msg = JSON.parse(result)
					# console.log("Result:",result); #debug.printAllincommingUDPmessages

					if (!msg.hasOwnProperty('e'))
						console.error("msg does not have an e property", msg)
						return;

					if (msg.hasOwnProperty('core_id') || msg.hasOwnProperty('id'))
						id = msg['core_id']||msg['id']
						@core_map[id] = rinfo.address #update the core_map
						console.info("core_map updated %s = %s", id, rinfo.address)

					handlers = @event_map[msg.e]
					if handlers == undefined
						console.warn("no handlers defined for", msg.e, msg)
						return

					for handler in handlers
						handler(null, msg, rinfo) #callbacks must be in the format err, data
				else
					console.error("ERROR", err, result, data)

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

		# packets in communication with the core will have a monotonically increasing
		# number, so we can identify the reply.
		@counter += 1;
		if @counter >= 255
			@counter = 0;

		mycnt = @counter

		cnt = mycnt.toString(16) #convert to base 16
		if cnt.length %2 != 0 # pad with zero
			cnt = "0"+cnt;

		out = cnt+out;

		out1 = new Buffer(out, "hex");
		client = dgram.createSocket("udp4")
		client.send out1, 0, out1.length, @settings.outgoing_udp_port, ip, (err, bytes) =>
			client.close();
			client = null;
			console.log("Sent: ",out); #debug.printAllOutgoingUDPmessages

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
		@send 0x020FFF1FFF, ip, (err, reply) ->
			if not err and reply.result == 1
				callback(null, reply) # Subscription created
			else
				callback(err||"Unable to create subscription", reply)

	# destroy a data subscripton
	destroySub: (core_id, callback) ->
		@send 0x0802, ip, (err, reply) ->
			console.log("destroy", reply);
			if not err and reply.result == 1
				callback(null, reply) # Subscription destroyed
			else
				callback(err||"Unable to destroy subscription", reply)


	#create a subscription with the core for high-speed data
	createSubFast: (core_id, callback) ->
		@send 0x0400FF10FF, core_id, (err, reply) ->
			if not err and reply.result == 1
				callback(null, reply) # Fast-Data Subscription Created
			else
				callback(err||(core_id+" unable to create FastSub"), null)


	#destroy the subscription for high-speed data
	destroySubFast: (core_id, callback) ->
		@send 0x0804, @core_map[core_id], (err, reply) ->
			if not err
				callback(null, reply) # Fast-Data Subscription Destroyed
			else
				callback(err||("unable to destroy FastSub"), null)


	# set the state of the outlets
	control: (core_id, outlet, state, callback) ->
		top = 0x0100 #top outlet
		bot = 0x0110 #bottom outlet

		if (outlet == "outlet1")
			msg = top
		else if (outlet == "outlet2")
			msg = bot
		else
			callback('Unknown Outlet '+outlet, null)
			return

		if (state == 'on')
			msg |= 0x0001;
			expect = 1
		else if (state == 'off')
			msg |= 0x0000;
			expect = 0
		else
			callback('Unknown State '+state, null)
			return

		@send msg, core_id, (err, reply) ->
			if not err and reply.result[0].state == expect
				# console.info("%s set to %s",outlet, state)
				callback(null, reply) #success changin state
			else
				# console.error("FAIL: could not set %s to %s", outlet, state)
				callback(err||"Could not set "+outlet+" to "+state, reply)

	# get measuement data
	getData: (core_id) ->
		console.log("I don't know how to \"getData\" yet, can you teach me?")

	# read the state of the outlets
	getState: (core_id, callback) ->
		@send 0x010212, core_id, (err, reply) ->
			# console.log("reply", err, reply)
			callback(err, reply)

	getCoreMap: ()->
		return @core_map

module.exports = CoreComm
