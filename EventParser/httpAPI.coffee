

class httpAPI

	constructor: (@settings) ->

		express = require('express')
		app = express()

		app.get '/',  (req, res) ->
		  res.send('Hello World!')

		app.get '/createSub', (req, res) ->
			res.send("test")

		app.get '/destroySub', (req, res) ->
			res.send("test")

		app.get '/control', (req, res) ->
			res.send("test")

		app.get '/getData', (req, res) ->
			res.send("test")

		app.get '/getState', (req, res) ->
			res.send("test")



		server = app.listen @settings.listen_http_port,  () ->

		  host = server.address().address
		  port = server.address().port

		  console.log('HttpAPI listening at http://%s:%s', host, port)

module.exports = httpAPI