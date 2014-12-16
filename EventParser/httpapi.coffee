console = require('better-console')
_ = require('lodash')

class HttpAPI

	constructor: (@settings, @corecomm) ->

		express = require('express')
		app = express()
		app.set('views', __dirname + '/views')
		app.set('view engine', 'jade')

		RouteManager = require('./custom_modules/express-shared-routes').RouteManager
		routes = new RouteManager()

		# Expose the route manager to the views
		app.all '*',  (req,res,next) ->
			res.locals.routes = routes
			next()

		routes.get {name: "index", re: '/'}, (req, res) ->
			out = {
				'doc':{
					'index': {
						'text':'This is the page you are looking at!'
					}
					'createSub': {
						'text':'Creates a data subscription with the core.'
						'ex':['/createSub/192.168.1.147']
					}
					'destroySub': {
						'text':'Destroys a data subscription with the core.'
						'ex':['/destroySub/48ff6c065067555026311387']
					}
					'control': {
						'text':'Change the state of an outlet.'
						'ex':[
							'/control/48ff6c065067555026311387/1/on'
							'/control/48ff6c065067555026311387/1/off'
							'/control/48ff6c065067555026311387/2/on'
							'/control/48ff6c065067555026311387/2/off'
						]
					}
					'getData': {
						'text':'Request measurement data from the core.'
						'ex':''
					}
					'getState': {
						'text':'Get the state of the outlets connected to the core.'
						'ex':[
							'/getState/48ff6c065067555026311387'
						]
					}
				}
				'routes': routes.exportRoutes()
			}
			res.render('index', out)



		routes.get {name: 'createSub', re:'/createSub/:ip'}, (req, res) =>
			@corecomm.createSub req.params['ip'], (err, reply) ->
				res.send({'err':err, 'reply':reply})

		routes.get {name: 'destroySub', re:'/destroySub/:core_id'}, (req, res) =>
			@corecomm.destroySub req.params['core_id'], (err, reply) ->
				res.send({'err':err, 'reply':reply})

		routes.get {name: 'control', re:'/control/:core_id/:outlet/:state'}, (req, res) =>
			outletnum = req.params['outlet'].replace('outlet','')
			state = req.params['state']
				if _.isBoolean(req.params['state'])
					state = req.params['state']?"on":"off"

			@corecomm.control req.params['core_id'], 'outlet'+outletnum, , (err, reply) ->
				res.send({'err':err, 'reply':reply})

		# routes.get {name: 'getData', re:'/getData/:core_id/'}, (req, res) =>
		# 	res.send("Not currently implimented!")

		routes.get {name: 'getState', re:'/getState/:core_id'}, (req, res) =>
			@corecomm.getState req.params['core_id'], (err, reply) ->
				res.send({'err':err, 'reply':reply})

				# createFastSub @todo
				# destroyFastSub @todo

		# add the routes to the app
		routes.applyRoutes(app);

		server = app.listen @settings.listen_http_port,  () ->

			host = server.address().address
			port = server.address().port

			console.info('HttpAPI listening on port %s', port)
			console.log(""); #add a blank line

module.exports = HttpAPI
