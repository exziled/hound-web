
# sub = new Buffer("020000", "hex"); #init a subscription
# sub_close = new Buffer("020000", "hex"); #close a subscription
# sub_fast = new Buffer("04", "hex"); #init a high-speed subscription
# sub_fast_close = new Buffer("020000", "hex"); #close a high-speed subscription

# cmd_set_top_on  = new Buffer("01B101", "hex");
# cmd_set_top_off = new Buffer("01B100", "hex");

# cmd_set_bottom_on  = new Buffer("01B001", "hex");
# cmd_set_bottom_off = new Buffer("01B000", "hex");

class SocketIO

	constructor: (@udp_server, @settings)->

		@coresock = {}

		wsServer = require('ws').Server;
		wss = new wsServer({port: +@settings.websock_port});

		console.log("Core Server Listening on port "+@settings.websock_port);

		wss.on 'connection', (ws) =>
			console.log('WebSocket Core Client Connected');
			ws.on 'message', (message) =>
				console.log(message);
				#When data is recieved from a sparkcore emit the data to any subscribed
				#web clients. try/catch for malformated json data.
				try
					message = JSON.parse(message);
					if (message['id'] == undefined)
						console.log("id is undefined");

					sockets = @coresock[message.id];
					for sock in sockets
						sock.emit('data', message);

				catch err
					console.log(err, message);

			ws.on 'close', () ->
				console.log('SparkCore disconnected.');

			ws.on 'error', (err) ->
				console.log('SparkERROR', err);

		@io = require('socket.io')(settings.socketio_port);
		console.log("Socket.IO server listening on port "+settings.socketio_port);
		@io.on 'connection', (socket) =>

			socket.on 'who', (coreid) =>

				console.log('socket.io web user connected', coreid);
				socket['coreid'] = coreid;
				if (@coresock[coreid] == undefined)
					@coresock[coreid] = [socket];

					#create a subscription with the core for high-speed data
					@udp_server.send 0x04, "192.168.1.113", (err, reply) ->
						console.log("Websockets ",err, reply); #@todo test this
						if not err and reply.result == 1
							console.log("Websockets Subscription Created with", coreid);
				else
					@coresock[coreid].push(socket);

			#send the current state of the outlets to the web client so they can accurately show the state.
			socket.on 'status', () =>

				#read the current data from the core
				# @udp_server.send 0x01B002, "192.168.1.113", (err, reply) -> #B102
				# 	console.log("WS Status ",err, reply); #@todo test this

				# 	data = {
				# 		outlet1: "off" #@todo
				# 		outlet2: "off" #@todo
				# 	}
				# 	socket.emit('status', data)


			socket.on 'disconnect', () =>
				coreid = socket['coreid'];
				console.log('socket.io web user disconnected', coreid);

				sockets = @coresock[coreid];
				for sock in sockets
					if (sock.id == socket.id)
						sockets.splice(sockets.indexOf(sock),1); #remove the matching element
						break;

				@coresock[coreid] = sockets;
				if (sockets.length == 0) #last socket removed
					#destroy the subscription for high-speed data
					@udp_server.send 0x05, "192.168.1.113", (err, reply) ->
						console.log("WS Destroy ",err, reply); #@todo test this

			socket.on 'control', (data) =>

				# top = 0x01B100
				# bot = 0x01B000

				# if (data.outlet == "outlet1")
				# 	msg = top
				# else if (data.outlet == "outlet2")
				# 	msg = bot
				# else
				# 	console.log("Unknown Outlet ", data.outlet);
				# 	return;

				# if (data.state == 'on')
				# 	msg |= 0x01;
				# else if (data.state == 'off')
				# 	msg |= 0x00;
				# else
				# 	console.log("Unknown State ", data.state);
				# 	return;

				# @udp_server.send msg, "192.168.1.113", (err, reply) ->
				# 	console.log("control ",err, reply); #@todo test this

module.exports = SocketIO