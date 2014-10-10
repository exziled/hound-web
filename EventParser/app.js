var spark = require('spark');
var request = require('request');
var _ = require('underscore');


// spark.login({accessToken: 'b122a221bf419da7491e4fca108f1835a2794451'}, function(err, body){
// 	// console.log(err, body);
// 	if (!err) {
// 		spark.getEventStream(false, 'mine', function(data) {
// 			console.log("Event: " + data);
// 		});
// 	} else {
// 		console.log("ERROR: ",err);
// 	}
// });

//settings

// var PORT = 3000;

// var app = require('http').createServer()
// var io = require('socket.io')(app);
// var fs = require('fs');

// app.listen(PORT, function () {
// 	console.log("Listening on port "+PORT);
// });

// function handler (req, res) {
//   fs.readFile(__dirname + '/index.html',
//   function (err, data) {
//     if (err) {
//       res.writeHead(500);
//       return res.end('Error loading index.html');
//     }

//     res.writeHead(200);
//     res.end(data);
//   });
// }

// io.on('connection', function (socket) {
//   socket.emit('news', { hello: 'world' });
//   socket.on('my other event', function (data) {
//     console.log(data);
//   });
// });

var wsport = 8080;
var wsServer = require('ws').Server
, wss = new wsServer({port: wsport});

console.log("Core Server Listening on port "+wsport);

wss.on('connection', function(ws) {
    console.log('Client Connected');
    ws.on('message', function(message) {
        // console.log('recieved: %s - size: %d', message, message.length);
        console.log(message);
    });

    ws.on('close', function() {
        console.log('Client disconnected.');
    });
    ws.on('error', function() {
        console.log('ERROR');
    });

    // ws.send('ohaidere');

    // setInterval(function() {
    //    ws.send('delayed!');
    // }, 2000);
});

var ioport = 2648;
var io = require('socket.io')(ioport);
console.log("Socket.IO Server Listening on port "+ioport);
io.on('connection', function(socket){
  console.log('a web user connected');
  // console.log('socketid ',socket.id);

  // socket.emit('message', "fred");

  socket.on('who', function(coreid){
  	console.log(coreid);
  	socket['coreid'] = coreid;
  	if (coresock[coreid] === undefined) {
  		coresock[coreid] = [socket];
  	} else {
  		coresock[coreid].push(socket);
  	}
  })

  socket.on('disconnect', function(){
  	var coreid = socket['coreid'];
    console.log('web user disconnected', coreid);
    var sockets = coresock[coreid];
    for (var i = 0; i < sockets.length; i++) {
    	if (sockets[i].id == socket.id) {
    		sockets.splice(i,1); //remove the matching element
    		break;
    	}
    };
    coresock[coreid] = sockets;
  });

});

var coresock = {};
// {"48ff6c065067555026311387": [socket, socket]}

// setInterval(function () {
// 	console.log(coresock);
// }, 2000)