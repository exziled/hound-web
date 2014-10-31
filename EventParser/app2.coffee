
#settings
settings =
	listen_udp_port:8081
	outgoing_udp_port:9080



UDP_Server = require('./core_udp_server.coffee');
udp_server = new UDP_Server(settings);


# console.log(udp_server)

#messages
sub = new Buffer("01020000", "hex"); #init a subscription
# sub_close = new Buffer("020000", "hex"); #close a subscription

#create a subscription with the core
udp_server.send sub, "192.168.1.113", (err, reply) ->
	console.log(error, reply)

udp_server.on 'samp', (err, data) ->
	console.log(err, data)

udp_server.on 'ws', (err, data) ->
	console.log(err, data)

# client = dgram.createSocket("udp4");
# client.send(sub, 0, sub.length, settings.outgoing_udp_port, "192.168.1.113", function(err, bytes) {
# 	client.close();
# 	client = null;
# });
