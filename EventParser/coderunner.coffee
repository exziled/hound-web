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

	runCode: (code2run, callback) ->
		if not @codetempl
			callback("error: code template not loaded")
			return
		else
			code = @codetempl.replace("{{code}}", code2run)
			# console.log("Running: |", code,"|");
			@s.run code, (output) ->
				callback(null, output)

module.exports = CodeRunner