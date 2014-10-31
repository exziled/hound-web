
#settings
settings =
	listen_udp_port:8081
	outgoing_udp_port:9080


http = require('http')
UDP_Server = require('./core_udp_server.coffee')
udp_server = new UDP_Server(settings)


# console.log(udp_server)

#messages
sub = new Buffer("01020000", "hex"); #init a subscription
# sub_close = new Buffer("020000", "hex"); #close a subscription

#create a subscription with the core
udp_server.send sub, "192.168.1.113", (err, reply) ->
	console.log(error, reply) #currently there is no reply to a subscription request

udp_server.on 'samp', (err, data, rinfo) ->
	if (err)
		console.log("sample error", err);
	else
		try
			# data = JSON.parse(data);

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

udp_server.on 'ws', (err, data) ->
	console.log(err, data)

# client = dgram.createSocket("udp4");
# client.send(sub, 0, sub.length, settings.outgoing_udp_port, "192.168.1.113", function(err, bytes) {
# 	client.close();
# 	client = null;
# });
