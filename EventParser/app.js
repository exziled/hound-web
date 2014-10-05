var spark = require('spark');
var request = require('request');


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

var PORT = 3000;

var app = require('http').createServer()
var io = require('socket.io')(app);
var fs = require('fs');

app.listen(PORT, function () {
	console.log("Listening on port "+PORT);
});

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

io.on('connection', function (socket) {
  socket.emit('news', { hello: 'world' });
  socket.on('my other event', function (data) {
    console.log(data);
  });
});