var dgram = require('dgram');
var json_sanitizer = require('json_sanitizer');

//globals
var event_map = {}; //{"event_name": [callbacks]}

var settings = {};


module.exports = function(listen_udp_port, outgoing_udp_port) {
	settings['listen_udp_port'] = listen_udp_port;
	settings['outgoing_udp_port'] = outgoing_udp_port;

	var server = dgram.createSocket('udp4');
	server.bind(listen_udp_port);

	server.on("error", function (err) {
		console.log("server error:\n" + err.stack);
		server.close();
	});

	server.on("listening", function () {
		var address = server.address();
		console.log("UDP server listening on port " + address.port);
		console.log("");
	});

	server.on("message", function (data, rinfo) {
		data = ""+data; //convert the buffer to a string
		data = data.replace(/\0/,''); //@todo shouldn't need this

		json_sanitizer(data, function(err, result){
			if (!err) {
				var msg = JSON.parse(result);
				// @todo: this is a hack for now
				if (msg.hasOwnProperty('s_id')) {
					msg.e = 'samp';
				}
				if (msg.hasOwnProperty('s')) {
					msg.e = 'ws';
				}
				//@end hack
				if (!msg.hasOwnProperty('e')) {
					return;
				}

				var handlers = event_map[msg.e];
				for (var i = 0; handlers !== undefined && i < handlers.length; i++) {
					handlers[i](null, msg); //callbacks must be in the format err, data
				}

			} else {
				console.log("ERROR", err, result, data);
			}
		});
	});

};

//callbacks must be in the format err, data
module.exports.on = function(evt, callback) {
	if (event_map[evt] === undefined) {
		event_map[evt] = [callback];
	} else {
		event_map[evt].push(callback);
	}
};

//pass the same callback to remove
exports.off = function(evt, callback) {
	if (event_map[evt] === undefined) {
		return;
	} else {
		if (event_map[evt].length == 1) { //this will help prevent memory leaks...
			delete event_map[evt];
			return;
		}
		if (callback === undefined) {
			console.log("Unable to remove handler");
			return;
		}
		var idx = event_map[evt].indexOf(callback);
		event_map[evt].splice(idx, 1); //remove from array
	}
};

//callback is in the format (err, data)
module.exports.send = function(buff, ip, callback) {
	//@todo generate random packetID & send
	var client = dgram.createSocket("udp4");
	client.send(subbuffer, 0, buffer.length, settings.outgoing_udp_port, ip, function(err, bytes) {
		client.close();
		client = null;
		//@todo on('reply_packetID', function(err, data){
		//callback(err, data);
		//off('reply_packetID');
		//});
	});
};