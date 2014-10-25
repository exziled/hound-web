var request = require('request');
var _ = require('underscore');

// -----------------------------------------------------------------------------
// High-Speed data from cores using websockets
// -----------------------------------------------------------------------------

// port to run the web socket server on which to listen for new data from the core.
var wsport = 8080;

var wsServer = require('ws').Server;
var wss = new wsServer({port: wsport});

// variable to keep track of what web client is interested in what core.
// This allows for easy lookup of subscribed web clients when the core sends new data.
var coresock = {};
// {"48ff6c065067555026311387": [socket, socket]}

console.log("Core Server Listening on port "+wsport);

wss.on('connection', function(ws) {
	console.log('Client Connected');
	ws.on('message', function(message) {
		//When data is recieved from a sparkcore emit the data to any subscribed
		//web clients. try/catch for malformated json data.
		try	{
			message = JSON.parse(message);
			var sockets = coresock[message.coreid];
			for (var i = 0; sockets !== undefined && i < sockets.length; i++) {
				sockets[i].emit('data', message);
			}
		} catch(err) {
			console.log(err, message);
		}
	});

	ws.on('close', function() {
		console.log('SparkCore disconnected.');
	});
	ws.on('error', function(err) {
		console.log('SparkERROR', err);
	});
});

// -----------------------------------------------------------------------------
// High-Speed data pushed to socket.io clients
// -----------------------------------------------------------------------------

// Port to run socket.io on for web clients.
var ioport = 2648;
var io = require('socket.io')(ioport);
console.log("Socket.IO Server Listening on port "+ioport);
io.on('connection', function(socket){

	socket.on('who', function(coreid){

		console.log('socket.io web user connected', coreid);
		socket['coreid'] = coreid;
		if (coresock[coreid] === undefined) {
			coresock[coreid] = [socket];
		} else {
			coresock[coreid].push(socket);
		}
	})

	socket.on('disconnect', function(){
		var coreid = socket['coreid'];
		console.log('socket.io web user disconnected', coreid);

		var sockets = coresock[coreid];
		for (var i = 0; i < sockets.length; i++) {
			if (sockets[i].id == socket.id) {
				sockets.splice(i,1); //remove the matching element
				break;
			}
		}
		coresock[coreid] = sockets;
	});

});