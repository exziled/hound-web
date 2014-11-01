
# sub = new Buffer("020000", "hex"); #init a subscription
# sub_close = new Buffer("020000", "hex"); #close a subscription
# sub_fast = new Buffer("04", "hex"); #init a high-speed subscription
# sub_fast_close = new Buffer("020000", "hex"); #close a high-speed subscription

# cmd_set_top_on  = new Buffer("01B101", "hex");
# cmd_set_top_off = new Buffer("01B100", "hex");

# cmd_set_bottom_on  = new Buffer("01B001", "hex");
# cmd_set_bottom_off = new Buffer("01B000", "hex");

class SocketIO

	constructor: (@udp_server, @settings, @coremap)->

		@coresock = {}

		# -----------------------------------------------------------------------------
		# High-Speed data from cores using websockets
		# -----------------------------------------------------------------------------
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

		# -----------------------------------------------------------------------------
		# High-Speed data and control pushed to socket.io web clients
		# -----------------------------------------------------------------------------

		@io = require('socket.io')(settings.socketio_port);
		console.log("Socket.IO server listening on port "+settings.socketio_port);
		@io.on 'connection', (socket) =>

			socket.on 'who', (coreid) =>

				console.log('socket.io web user connected', coreid);
				socket['coreid'] = coreid;
				if (@coresock[coreid] == undefined) # no web users are subscribed to data from this fore

					if @coremap[coreid] == undefined
						console.log("unable to create socketio sub with core b/c its not registered in the coremap", coreid);
						return;

					@coresock[coreid] = [socket];

					#create a subscription with the core for high-speed data
					@udp_server.send 0x04, @coremap[coreid], (err, reply) ->
						if not err and reply.result == 1
							console.log("Websockets Subscription Created with", coreid);
				else #others are already subscribed so lets just add us to the list of interested clients
					@coresock[coreid].push(socket);

			#send the current state of the outlets to the web client so they can accurately show the state.
			socket.on 'status', () =>
				coreid = socket['coreid'];
				if @coremap[coreid] == undefined
					console.log("unable to get status of core b/c its not registered in the coremap", coreid);
					return

				#read the current data from the core
				@udp_server.send 0x01B102B002, @coremap[coreid], (err, reply) -> #B102
					console.log("reply",err, reply); #@todo test this

					console.log(reply, reply.result, reply.result[0], reply.result[0].state);
					data = {
						outlet1: if reply.result[1].state then "on" else "false"
						outlet2: if reply.result[0].state then "on" else "false"
					}
					console.log(data);
					socket.emit('status', data)


			socket.on 'disconnect', () =>
				coreid = socket['coreid'];
				console.log('socket.io web user disconnected', coreid);

				sockets = @coresock[coreid];
				if sockets != undefined
					#remove the sockets of the leaving clients from our coresock map
					for sock in sockets
						if (sock.id == socket.id)
							sockets.splice(sockets.indexOf(sock),1); #remove the matching element
							break;
					@coresock[coreid] = sockets;

					if (sockets.length == 0) #last socket removed
						if @coremap[coreid] == undefined
							console.log("unable to destroy websocket sub core b/c its not registered in the coremap", coreid);
							return
						#destroy the subscription for high-speed data
						@udp_server.send 0x0401, @coremap[coreid], (err, reply) ->
							console.log("WS Destroy ",err, reply); #@todo test this

			socket.on 'control', (data) =>

				coreid = socket['coreid'];
				if @coremap[coreid] == undefined
					console.log("unable to set outlet status b/c the core is not registered in the coremap", coreid);
					return

				top = 0x01B000 #b0
				bot = 0x01B100 #b1

				if (data.outlet == "outlet1")
					msg = top
				else if (data.outlet == "outlet2")
					msg = bot
				else
					console.log("Unknown Outlet ", data.outlet);
					return;

				if (data.state == 'on')
					msg |= 0x01;
				else if (data.state == 'off')
					msg |= 0x00;
				else
					console.log("Unknown State ", data.state);
					return;

				@udp_server.send msg, @coremap[coreid], (err, reply) ->
					console.log("control ",err, reply); #@todo test this

module.exports = SocketIO