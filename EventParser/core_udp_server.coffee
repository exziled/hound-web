dgram = require('dgram')
json_sanitizer = require('json_sanitizer')

delay = (ms, func) -> setTimeout func, ms

class UDP_Server

	constructor: (@settings) ->
		@event_map = {}
		@counter = 0;
		server = dgram.createSocket('udp4');
		server.bind @settings.listen_udp_port, ()=>
			server.addMembership("224.111.112.113")

		server.on "error", (err) =>
			console.log("server error:\n" + err.stack)
			server.close()


		server.on "listening", () =>
			address = server.address();
			console.log("UDP server listening on port " + address.port);
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
		console.log("on", evt);
		if (not (evt of @event_map))
			@event_map[evt] = [callback]
		else
			@event_map[evt].push(callback)

	#pass the same callback to remove
	off: (evt, callback) ->
		console.log("off", evt);
		if (not (evt of @event_map))
			return
		else
			if (@event_map[evt].length == 1) #allow removal with only evtname if its the only handler
				delete @event_map[evt]
				return

			if (callback == undefined)
				console.log("Unable to remove handler")
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

		cnt = @counter.toString(16) #convert to base 16
		if cnt.length %2 != 0
			cnt = "0"+cnt;

		out = cnt+out;

		out1 = new Buffer(out, "hex");
		client = dgram.createSocket("udp4")
		client.send out1, 0, out1.length, @settings.outgoing_udp_port, ip, (err, bytes) =>
			client.close();
			client = null;
			console.log("Sub Req",out);

			timeoutID = delay 8000, ()=>
				console.log("UDP Timed out");
				@off @counter.toString()
				@send(buff, ip, callback);

			@on @counter.toString(), (err, data) =>
				clearTimeout(timeoutID) #if we get a reply clear the timeout
				callback(err, data);
				@off @counter.toString()





module.exports = UDP_Server
