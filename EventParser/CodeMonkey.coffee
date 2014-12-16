
request = require('request')
_ = require('lodash')
json_sanitizer = require('json_sanitizer')

CodeRunner = require('./coderunner.coffee')
coderunner = new CodeRunner()

env = process.env.NODE_ENV || 'dev';

API_ENDPOINT = 'http://houndplex.plextex.com'
if env == 'dev'
	API_ENDPOINT = 'http://hound'


devicesWithProgram = (callback) ->
	request API_ENDPOINT+'/api/program', (err, res, body) ->
		if not err and res.statusCode == 200
			try
				data = JSON.parse(body)
			catch e
				console.error("HTTP Error: ", e)
				callback(e, null)
				return

			callback(null, _.pluck(data, 'device_id'))
		else
			callback(err||("bad status code "+res.statusCode), null)

deviceProgram = (device_id, callback) ->
	request API_ENDPOINT+'/api/program/'+device_id, (err, res, body) ->
		if not err and res.statusCode == 200
			try
				data = JSON.parse(body)
			catch e
				console.error("HTTP Error: ", e)
				callback(e, null)
				return

			callback(null, data)
		else
			callback(err||("bad status code "+res.statusCode), null)

latestSample = (device_id, callback) ->
	request API_ENDPOINT+'/api/sample/'+device_id, (err, res, body) ->
		if not err and res.statusCode == 200
			try
				data = JSON.parse(body)
			catch e
				console.error("HTTP Error: ", e)
				callback(e, null)
				return

			callback(null, data)
		else
			callback(err||("bad status code "+res.statusCode), null)

control = (coreid, outlet, state, callback) ->
	if _.isBoolean(state)

		state = if state then "on" else "off"
	url = 'http://houndplex.plextex.com'+':8082/control/'+coreid+'/'+outlet+'/'+state #@todo API_ENDPOINT

	request url, (err, res, body) ->
		if not err and res.statusCode == 200
			try
				data = JSON.parse(body)
			catch e
				console.error("HTTP Error: ", e)
				callback(e, null)
				return

			callback(null, data)
		else
			callback(err||("bad status code "+res.statusCode), null)



# deviceProgram 14, (err, data)->
# 	console.log(err,data);



# * * * * *
# │ │ │ │ └─ day of week (0 - 6) (0 to 6 are Sunday to Saturday, or use names; 7 is Sunday, the same as 0)
# │ │ │ └─── month (1 - 12)
# │ │ └───── day of month (1 - 31)
# │ └─────── hour (0 - 23)
# └───────── min (0 - 59)


# crontab = require('node-crontab')
# jobId = crontab.scheduleJob "*/10 * * * *", ()->
# 	console.log("%s we are starting!", Date.now())

# console.log("%s Init complete", Date.now())

#"* * * * *" # every minute
#"*/10 * * * *" # every 10 minutes

# Every 10 minutes:
coderunner.loadTemplate (err, reply) ->
	if err
		console.log("Unable to load template")
	else
		devicesWithProgram (err, devices) ->
			if err
				console.log("unable to get list of devices, try again in 10 mins", err)
				return
			else
				# console.log(devices);
				for device_id in devices
					# console.log("Device %s", device_id);
					deviceProgram device_id, (err, prgmdata) ->
						# console.log(prgmdata);
						if err
							console.log("Unable to get program for ", device_id, err)
							return
						else
							latestSample device_id, (err, samples)->
								if err
									console.log("Unable to samples for ", device_id, err)
									return
								else
									coderunner.runCode samples, prgmdata.javascript, (err, output)->
										# console.log("done?", output.result);
										json_sanitizer output.result, (err, result) =>
											if err
												console.error('Unable to parse result: ', output)
											else
												result =  JSON.parse(result)
												# Handle Email
												# Handle SMS - later
												# Handle Control
												for outlet of result.control
													control prgmdata.core_id, outlet, result.control[outlet], (err, data) ->
														if err
															console.error("Unable to change socket state",err);

