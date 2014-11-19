
#settings
settings =
	listen_udp_port:8081			# listen fro replies from the core on this port
	outgoing_udp_port:9080			# send messages to the core on this port
	socketio_port:2648				# port that socketio web communication uses
	# websock_port:9081				# high speed data from the core
	udp_timeout:3000				# how long to wait after sending a packet before resend
	udp_multicast:"224.111.112.113"	# port to listen on fro broadasts from cores

http = require('http')
UDP_Server = require('./core_udp_server.coffee')
udp_server = new UDP_Server(settings)

# Holds the relation between cores and their ipaddresses
# http://stackoverflow.com/questions/518000
coremap = {} # {"coreid":"ipaddress"}

SocketIO = require('./socketio.coffee')
socketio = new SocketIO(udp_server, settings, coremap)

env = process.env.NODE_ENV || 'dev';
console.log("Server running in %s mode", env);

#triggered on new sample set
udp_server.on 'samp', (err, data, rinfo) ->
	coremap[data.core_id] = rinfo.address #update the coremap
	if (err)
		console.log("sample error", err);
	else
		try
			# console.log(data);

			options = {
				host: 'hound',
				path: '/api/samples',
				method: 'POST',
				headers: {
					"Content-Type":"application/json"
				}
			}
			# if env == "production"
				# options.host = "houndplex.plextex.com"
			callback = (res) ->
				str = ''
				res.on 'data', (chunk) ->
					str += chunk;


				res.on 'end', () ->
					if (res.statusCode == 201)
						console.log("%s Data Logged to server from core", new Date().getTime(), data.core_id);
					else
						console.error(res.statusCode, str);
			try
				req = http.request(options, callback);
			catch e
				console.log("ERROR: Sending HTTP request ", e);

			# This is the data we are posting, it needs to be a string or a buffer
			req.write(JSON.stringify(data));
			req.end();

		catch e
			console.log("udp_server.on 'samp'", e, data);


#triggered when core comes online
udp_server.on 'broadcast', (err, data, rinfo) ->
	coremap[data.id] = rinfo.address  #update the coremap
	#automatically create subscription when a core comes online
	udp_server.send 0x2, rinfo.address, (err, reply) ->
		if not err and reply.result == 1
			console.log("Subscription created with core",data.id);
