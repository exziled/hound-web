
request = require('request')
_ = require('lodash')

CodeRunner = require('./coderunner.coffee')
coderunner = new CodeRunner()


devicesWithProgram = (callback) ->
	request 'http://hound/api/program', (err, res, body) ->
		if not err and res.statusCode == 200
			try
				data = JSON.parse(body)
			catch e
				console.error("HTTP Error: ", e)
				callback(e, null)
				return

			callback(null, _.pluck(data, 'device_id'))

deviceProgram = (device_id, callback) ->
	request 'http://hound/api/program/'+device_id, (err, res, body) ->
		if not err and res.statusCode == 200
			try
				data = JSON.parse(body)
			catch e
				console.error("HTTP Error: ", e)
				callback(e, null)
				return

			callback(null, data)


# * * * * *
# │ │ │ │ └─ day of week (0 - 6) (0 to 6 are Sunday to Saturday, or use names; 7 is Sunday, the same as 0)
# │ │ │ └─── month (1 - 12)
# │ │ └───── day of month (1 - 31)
# │ └─────── hour (0 - 23)
# └───────── min (0 - 59)


# crontab = require('node-crontab')
# jobId = crontab.scheduleJob "*/10 * * * *", ()->
#     console.log("%s we are starting!", Date.now())

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
				for device_id in devices
					console.log("Device %s", device_id);
					deviceProgram device_id, (err, data) ->
						if err
							console.log("Unable to get program for ", device_id, err)
							return
						else
							coderunner.runCode data.javascript, ()->
								console.log("done?");

