dgram = require('dgram')
json_sanitizer = require('json_sanitizer')

class UDP_Server
	# @event_map = {}
	constructor: (@settings, @event_map={}) ->

		server = dgram.createSocket('udp4');
		server.bind(@settings.listen_udp_port);

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

					if (!msg.hasOwnProperty('e'))
						console.log("msg does not have an e property", msg);
						return;

					handlers = @event_map[msg.e]
					if handlers == undefined
						console.log("no handlers defined for", msg.e)
						return

					for handler in handlers
						handler(null, msg, rinfo) #callbacks must be in the format err, data
				else
					console.log("ERROR", err, result, data);

	#callbacks must be in the format err, data
	on: (evt, callback) ->
		if (not (evt of @event_map))
			@event_map[evt] = [callback]
		else
			@event_map[evt].push(callback)

	#pass the same callback to remove
	off: (evt, callback) ->
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
		#@todo generate random packetID & send
		client = dgram.createSocket("udp4")
		client.send buff, 0, buff.length, @settings.outgoing_udp_port, ip, (err, bytes) ->
			client.close();
			client = null;
			#@todo on('reply_packetID', function(err, data){
			#callback(err, data);
			#off('reply_packetID');
			#});




module.exports = UDP_Server