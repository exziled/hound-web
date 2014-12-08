
#settings
settings =
	listen_udp_port:8081			# listen fro replies from the core on this port
	outgoing_udp_port:9080			# send messages to the core on this port
	max_udp_retry:4					# number of retries to send UDP before Failing
	socketio_port:2648				# port that socketio web communication uses
	listen_http_port:8082			# high speed data from the core
	udp_timeout:3000				# how long to wait after sending a packet before resend
	udp_multicast:"224.111.112.113"	# addr to listen on for broadasts from cores

http = require('http')

CoreComm = require('./corecomm.coffee')
corecomm = new CoreComm(settings)

HttpAPI = require('./httpapi.coffee')
api = new HttpAPI(settings, corecomm)

SocketIO = require('./socketio.coffee')
socketio = new SocketIO(corecomm, settings)

env = process.env.NODE_ENV || 'dev';
console.log("Server running in %s mode", env);

#triggered on new sample sent from core
corecomm.on 'samp', (err, data, rinfo) ->

	if (err)
		console.log("sample error", err);
	else
		try
			options = {
				host: 'hound',
				path: '/api/samples',
				method: 'POST',
				headers: {
					"Content-Type":"application/json"
				}
			}
			if env == "production"
				options.host = "houndplex.plextex.com"


			req = http.request options, (res) ->
				str = ''
				res.on 'data', (chunk) ->
					str += chunk;

				res.on 'end', () ->
					if (res.statusCode == 201)
						console.log("%s Data Logged to server from core", new Date().getTime(), data.core_id);
					else
						console.error(res.statusCode, str);

			req.on 'error',  (err) ->
				console.log("HTTP ERROR: ",err);


			# This is the data we are posting, it needs to be a string or a buffer
			req.write(JSON.stringify(data));
			req.end();

		catch e
			console.log("corecomm.on 'samp'", e, data);


#triggered when core comes online
corecomm.on 'broadcast', (err, data, rinfo) ->

	#automatically create subscription when a core comes online
	corecomm.createSub rinfo.address, (err, reply) ->
		if not err
			console.log("Subscription created with core",data.id);
