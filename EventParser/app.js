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
console.log("Socket.IO server listening on port "+ioport);
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

// -----------------------------------------------------------------------------
// Perodic data from the SparkCore using UDP
// -----------------------------------------------------------------------------
var dgram = require('dgram');
var server = dgram.createSocket('udp4');
var udpport = 8081;
//messages
var sub = new Buffer("020000", "hex"); //init a subscription

server.on("error", function (err) {
	console.log("server error:\n" + err.stack);
	server.close();
});

server.on("listening", function () {
	var address = server.address();
	console.log("UDP server listening on port " + address.port);
	console.log("");
});

server.on("message", function (msg, rinfo) {

	//convert the buffer to a string
	data = ""+msg;
	//properly escape quotes and remove extra null characters
	data = data.replace(/\"/g,'\"').replace(/\0/,'');
	// var datagood = '{\"s_id\":\"0\",\"t\":[1414516577,1414516566,1414516555,1414516544,1414516533,1414516522],\"vrms\":[118.614,118.580,118.487,118.566,118.505,118.504],\"irms\":[0.140,0.146,0.146,0.146,0.140,0.140],\"app\":[16.705,17.315,17.302,17.313,16.690,16.689],}';
	// console.log(data == datagood, data, datagood);
	data = data.replace('],}',']}').trim();
	try {
		data = JSON.parse(data)
		console.log(data);
	} catch (e) {
		console.log("Invalid JSON: "+e+" | \""+data+"\"",e);
	}
	console.log("");
});

server.bind(udpport)

var client = dgram.createSocket("udp4");
client.send(sub, 0, sub.length, 9080, "192.168.1.113", function(err, bytes) {
	client.close();
});
