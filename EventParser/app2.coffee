
#settings
settings =
	listen_udp_port:8081
	outgoing_udp_port:9080
	socketio_port:2648
	websock_port:9081
	udp_timeout:3000

http = require('http')
UDP_Server = require('./core_udp_server.coffee')
udp_server = new UDP_Server(settings)

SocketIO = require('./socketio.coffee')
socketio = new SocketIO(udp_server, settings)


#create a subscription with the core
udp_server.send 0x2, "192.168.1.113", (err, reply) ->
	if not err and reply.result == 1
		console.log("Subscription created");

#triggered on new sample set
udp_server.on 'samp', (err, data, rinfo) ->
	if (err)
		console.log("sample error", err);
	else
		try
			#@todo replaceme
			if (rinfo.address == "192.168.1.111")
				data.core_id = "48ff6c065067555026311387";
			else if (rinfo.address == "192.168.1.113")
				data.core_id = "53ff6d065067544847310187";
			else
				data.core_id = "";
			#@end
			console.log(data);

			options = {
				host: 'hound',
				path: '/api/samples',
				method: 'POST',
				headers: {
					"Content-Type":"application/json"
				}
			}
			callback = (res) ->
				str = ''
				res.on 'data', (chunk) ->
					str += chunk;


				res.on 'end', () ->
					if (res.statusCode != 201)
						console.log(res.statusCode, str);

			req = http.request(options, callback);
			# This is the data we are posting, it needs to be a string or a buffer
			req.write(JSON.stringify(data));
			req.end();

		catch e
			console.log("udp_server.on 'samp'", e, data);

#triggered when core comes online
udp_server.on 'broadcast', (err, data, rinfo) ->
	#automatically create subscription
	udp_server.send 0x2, rinfo.address, (err, reply) ->
		if not err and reply.result == 1
			console.log("Subscription created");
