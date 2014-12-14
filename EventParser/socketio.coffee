console = require('better-console')

class SocketIO

	constructor: (@corecomm, @settings)->

		# Holds the relation between core_id's and the client sockets interested
		# in data from those devices { coreid: [client sockets] }
		@coresock = {}

		# relation between core_id and ipaddress
		@coremap = @corecomm.getCoreMap()

		# High speed data from the core
		@corecomm.on 'ws', (err, data, rinfo) =>

			# if the core does not send its ID that is an error
			if (data['core_id'] == undefined)
				console.error("ws core_id is undefined", data, rinfo);
				return;

			sockets = @coresock[data['core_id']];
			if sockets != undefined
				for sock in sockets
					sock.emit('data', data);
				console.info("%s Live data sent to web client for core %s", new Date().getTime(), data['core_id']);
			else
				console.warn("I'm getting data from %s but there are no subscribers", data['core_id']);
				# We can't destroy the subscription, becasue it can't be cancelled before the next set of data comes in
				# @corecomm.destroySubFast data['core_id'], (err, reply)->
				# 	if not err
				# 		console.warn("Fast Sub destroyed")
				# 	else
				# 		console.warn("Unable to destroy fast sub")


		# -----------------------------------------------------------------------------
		# High-Speed data and control pushed to socket.io web clients
		# -----------------------------------------------------------------------------

		@io = require('socket.io')(settings.socketio_port);
		console.info("Socket.IO server listening on port "+settings.socketio_port);

		# when a client connects
		@io.on 'connection', (socket) =>

			# ask the client what core they are interested in data for
			socket.on 'who', (coreid) =>

				console.info('socket.io web user connected', coreid);
				socket['coreid'] = coreid; #store the coreID on the socket object.

				# no web users are subscribed to data from this core
				if (@coresock[coreid] == undefined || @coresock[coreid].length == 0)

					if @coremap[coreid] == undefined
						console.error("FAIL: socketio sub create. %s not registered in coremap", coreid);
						return;

					# add the socket to the map
					@coresock[coreid] = [socket];

					#create a High-Speed subscription
					@corecomm.createSubFast coreid, (err, reply) ->
						if not err
							socket.emit('who') # tell the web client that the subscription was created
						else
							console.error(err);

				else #others are already subscribed so lets just add us to the list of interested clients
					@coresock[coreid].push(socket);
					socket.emit('who') # tell the web client that the subscription was created

			# when a client requests the state of a core's outlets
			socket.on 'status', () =>
				coreid = socket['coreid'];

				if @coremap[coreid] == undefined
					console.error("FAIL: get outlet status. %s not registered in coremap", coreid);
					return

				#read the current data from the core
				@corecomm.getState coreid, (err, reply) ->

					data = {
						outlet1: if reply.result[1].state then "on" else "false"
						outlet2: if reply.result[0].state then "on" else "false"
					}
					# send the current state of the outlets to the web client so they can accurately show the state.
					socket.emit('status', data)

			# when a client disconnects, (closes browser tab or navigates away)
			socket.on 'disconnect', () =>
				coreid = socket['coreid'];
				console.info('socket.io web user disconnected', coreid);

				sockets = @coresock[coreid];
				if sockets != undefined

					#remove the sockets of the leaving clients from our coresock map
					for sock in sockets
						if (sock.id == socket.id) #note: id is uniquely generated by socketio
							sockets.splice(sockets.indexOf(sock),1); #remove the matching element
							break;
					@coresock[coreid] = sockets;

					if (sockets.length == 0) #last socket removed
						if @coremap[coreid] == undefined
							console.error("FAIL: destroy websocket sub. %s not registered in coremap", coreid);
							return
						#destroy the subscription for high-speed data
						@corecomm.destroySubFast coreid, (err, reply) ->
							if not err
								console.info("FastSub Destroyed", reply)
							else
								console.info("Unable to destroy FastSub", err)

			# when a user asks for a state change
			socket.on 'control', (data) =>

				coreid = socket['coreid']
				if @coremap[coreid] == undefined
					console.error("FAIL: set outlet status. %s not registered in coremap", coreid)
					socket.emit('control_fail', coreid+" not registered in coremap")
					return

				@corecomm.control coreid, data.outlet, data.state, (err, data) ->
					console.log("corecom.control ",err,data);
					if not err
						socket.emit('control_success', data)
						@io.sockets.emit('status', data);
					else
						socket.emit('control_fail', err)

module.exports = SocketIO
