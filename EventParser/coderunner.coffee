Sandbox = require("sandbox")
fs = require("fs")
_ = require('lodash')

class CodeRunner
	constructor: (timeout) ->
		opts = {
			timeout: 500 #in miliseconds
		}
		if timeout && _.isNumber(timeout) && not _.isNaN(timeout)
			opts.timeout = timeout

		@s = new Sandbox(opts)
		@codetempl = undefined

	loadTemplate: (callback) ->
		fs.readFile './template.js', (err, code) =>
			if err
				callback(err,null)
				return
			@codetempl = code.toString('utf8');
			callback(null,code)

	runCode: (samples, code2run, callback) ->
		if not @codetempl
			callback("error: code template not loaded")
			return
		else
			code = @codetempl
			code = code.replace("{{code}}", code2run)

			DATA = {
				tempc: [55, 55],
				vrms: [120.5, 119.0],
				irms: [1.25, 1.25],
				app: [0, 0],
				real: [0, 0],
			}
			for sample in samples
				DATA.tempc[sample.socket] = sample.temperature
				DATA.vrms[sample.socket] = sample.voltage
				DATA.irms[sample.socket] = sample.current
				DATA.app[sample.socket] = sample.apparent_power
				DATA.real[sample.socket] = sample.real_power

			code = code.replace("{{data}}", JSON.stringify(DATA))

			@s.run code, (output) ->
				callback(null, output)

module.exports = CodeRunner