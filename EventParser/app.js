// -----------------------------------------------------------------------------
// High-Speed data from cores using websockets
// -----------------------------------------------------------------------------

// port to run the web socket server on which to listen for new data from the core.
var spark_udp_port = 9080;
var wsport = 9081;
var status_port = 9082;

var wsServer = require('ws').Server;
var wss = new wsServer({port: wsport});

// variable to keep track of what web client is interested in what core.
// This allows for easy lookup of subscribed web clients when the core sends new data.
var coresock = {};
// {"48ff6c065067555026311387": [socket, socket]}

console.log("Core Server Listening on port "+wsport);

wss.on('connection', function(ws) {
	console.log('WebSocket Core Client Connected');
	ws.on('message', function(message) {
		console.log(message);
		//When data is recieved from a sparkcore emit the data to any subscribed
		//web clients. try/catch for malformated json data.
		try	{
			message = JSON.parse(message);
			if (message['id'] === undefined) {
				console.log("id is undefined");
			}
			var sockets = coresock[message.id];
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
			//create a subscription with the core for high-speed data
			var client = dgram.createSocket("udp4");
			client.send(sub_fast, 0, sub_fast.length, spark_udp_port, "192.168.1.113", function(err, bytes) {
				console.log("Websockets Subscription Created");
				client.close();
				client = null;
			});
		} else {
			coresock[coreid].push(socket);
		}
	})
	//send the current state of the outlets to the web client so they can accurately show the state.
	socket.on('status', function(){

		// var read_state = new Buffer("01B102", "hex");
		// var client = dgram.createSocket("udp4")
		// client.send(sub_fast_close, 0, sub_fast_close.length, spark_udp_port, "192.168.1.113", function(err, bytes) {
		// 	client.close();
		// 	client = null;
		// });
		// var server = dgram.createSocket("udp4")
		// server.bind(status_port);
		// server.on('message', function(msg) {
		// 	console.log("Reply: ", msg)
		// })

		var data = {
			outlet1: "off", //@todo
			outlet2: "off" //@todo
		};
		socket.emit('status', data)
	});

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
		if (sockets.length == 0) {
			//destroy the subscription for high-speed data
			var client = dgram.createSocket("udp4")
			client.send(sub_fast_close, 0, sub_fast_close.length, spark_udp_port, "192.168.1.113", function(err, bytes) {
				client.close();
				client = null;
			});
		};
	});

	socket.on('control', function(data){
		console.log(data); //@todo send the control signal to the core via UDP
		//@todo coreid to IP address
		var address = "192.168.1.113";

		//@todo need a better way to handle the core port/pin #'s

		var message = cmd_set_off;
		if (data.state == 'on') {
			message = cmd_set_on;
		}
		var client = dgram.createSocket("udp4");
		client.send(message, 0, message.length, spark_udp_port, address, function(err, bytes) {
			client.close();
			client = null;
		});


	});

});

// -----------------------------------------------------------------------------
// UDP server listening for perodic data from the SparkCore using UDP
// -----------------------------------------------------------------------------
var dgram = require('dgram');
var http = require('http');

var server = dgram.createSocket('udp4');
var udpport = 8081;
//messages
var sub = new Buffer("020000", "hex"); //init a subscription
var sub_close = new Buffer("020000", "hex"); //close a subscription
var sub_fast = new Buffer("04", "hex"); //init a high-speed subscription
var sub_fast_close = new Buffer("020000", "hex"); //close a high-speed subscription

var cmd_set_on = new Buffer("01B101", "hex");
var cmd_set_off = new Buffer("01B100", "hex");


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
	// console.log("msg");
	// console.log("server got: " + msg + " from " + rinfo.address + ":" + rinfo.port);
	// 48ff6c065067555026311387
	//convert the buffer to a string
	data = ""+msg;
	//properly escape quotes and remove extra null characters
	data = data.replace(/\"/g,'\"').replace(/\0/,'');
	// var datagood = '{\"s_id\":\"0\",\"t\":[1414516577,1414516566,1414516555,1414516544,1414516533,1414516522],\"vrms\":[118.614,118.580,118.487,118.566,118.505,118.504],\"irms\":[0.140,0.146,0.146,0.146,0.140,0.140],\"app\":[16.705,17.315,17.302,17.313,16.690,16.689],}';
	// console.log(data == datagood, data, datagood);
	data = data.replace('],}',']}').trim();
	try {
		data = JSON.parse(data);

		if (rinfo.address == "192.168.1.111")
			data.core_id = "48ff6c065067555026311387";
		else if (rinfo.address == "192.168.1.113")
			data.core_id = "53ff6d065067544847310187";
		else
			data.core_id = "";
		console.log(data);

		var options = {
			host: 'hound',
			path: '/api/samples',
			method: 'POST',
			headers: {
				"Content-Type":"application/json"
			}
		};
		callback = function(res) {
			var str = ''
			res.on('data', function (chunk) {
				str += chunk;
			});

			res.on('end', function () {
				if (res.statusCode != 201) {
					console.log(res.statusCode, str);
				}
			});
		}

		var req = http.request(options, callback);
		//This is the data we are posting, it needs to be a string or a buffer
		// console.log(JSON.stringify(data));
		// console.log("hit");
		req.write(JSON.stringify(data));
		req.end();



	} catch (e) {
		console.log(e, data);
	}
});

server.bind(udpport)

//create a subscription with the core
var client = dgram.createSocket("udp4");
client.send(sub, 0, sub.length, spark_udp_port, "192.168.1.113", function(err, bytes) {
	client.close();
	client = null;
});

