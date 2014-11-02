
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

		console.info("Core Server Listening on port "+@settings.websock_port);

		wss.on 'connection', (ws) =>
			console.info('WebSocket Core Client Connected');
			ws.on 'message', (message) =>
				# console.log(message);
				#When data is recieved from a sparkcore emit the data to any subscribed
				#web clients. try/catch for malformated json data.
				try
					message = JSON.parse(message);
					if (message['id'] == undefined)
						console.log("id is undefined");

					sockets = @coresock[message.id];
					for sock in sockets
						sock.emit('data', message);
					console.info("%s Live data sent to web client for core %s", new Date().getTime(), message.id);
				catch err
					console.log(err, message);

			ws.on 'close', () ->
				console.log('SparkCore disconnected.');

			ws.on 'error', (err) ->
				console.error('SparkERROR', err);

		# -----------------------------------------------------------------------------
		# High-Speed data and control pushed to socket.io web clients
		# -----------------------------------------------------------------------------

		@io = require('socket.io')(settings.socketio_port);
		console.log("Socket.IO server listening on port "+settings.socketio_port);
		@io.on 'connection', (socket) =>

			socket.on 'who', (coreid) =>
				# console.log("coresock",@coresock);

				console.info('socket.io web user connected', coreid);
				socket['coreid'] = coreid;
				console.log("subscribers: ",@coresock[coreid]);
				if (@coresock[coreid] == undefined || @coresock[coreid].length == 0) # no web users are subscribed to data from this core
					console.log("Undefined!");

					if @coremap[coreid] == undefined
						console.log("FAIL: socketio sub create. %s not registered in coremap", coreid);
						return;

					@coresock[coreid] = [socket];

					#create a subscription with the core for high-speed data
					@udp_server.send 0x0400, @coremap[coreid], (err, reply) ->
						if not err and reply.result == 0
							console.info("Websockets Subscription Created with", coreid);
							socket.emit('who');
						else
							console.error("%s unable to create websockets subsription", coreid, reply);
				else #others are already subscribed so lets just add us to the list of interested clients
					# console.log("Added to list");
					@coresock[coreid].push(socket);

			#send the current state of the outlets to the web client so they can accurately show the state.
			socket.on 'status', () =>
				coreid = socket['coreid'];
				if @coremap[coreid] == undefined
					console.error("FAIL: get outlet status. %s not registered in coremap", coreid);
					return

				#read the current data from the core
				@udp_server.send 0x01B102B002, @coremap[coreid], (err, reply) -> #B102
					# console.log("reply",err, reply);

					# console.log(reply, reply.result, reply.result[0], reply.result[0].state);
					data = {
						outlet1: if reply.result[1].state then "on" else "false"
						outlet2: if reply.result[0].state then "on" else "false"
					}
					# console.log(data);
					socket.emit('status', data)


			socket.on 'disconnect', () =>
				coreid = socket['coreid'];
				console.info('socket.io web user disconnected', coreid);

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
							console.error("FAIL: destroy websocket sub. %s not registered in coremap", coreid);
							return
						#destroy the subscription for high-speed data
						@udp_server.send 0x0401, @coremap[coreid], (err, reply) ->
							console.info("WS Destroy ",err, reply); #@todo test this

				console.info("coresock disconnect", @coresock);

			socket.on 'control', (data) =>

				coreid = socket['coreid'];
				if @coremap[coreid] == undefined
					console.error("FAIL: set outlet status. %s not registered in coremap", coreid);
					return

				top = 0x01B000 #b0
				bot = 0x01B100 #b1

				if (data.outlet == "outlet1")
					msg = top
				else if (data.outlet == "outlet2")
					msg = bot
				else
					console.error("Unknown Outlet ", data.outlet);
					return;

				if (data.state == 'on')
					msg |= 0x01;
					expect = 1
				else if (data.state == 'off')
					msg |= 0x00;
					expect = 0
				else
					console.error("Unknown State ", data.state);
					return;

				@udp_server.send msg, @coremap[coreid], (err, reply) ->
					if not err and reply.result[0].state == expect
						console.info ("%s set to %s",data.outlet, data.state)
					else
						console.error("FAIL: could not set %s to %s", data.outlet, data.state);

module.exports = SocketIO