'use strict'

require! 'bluebird': Promise
require! 'lodash'
require! 'request-promise'

require! './compiler-args'
require! './langs.json'
require! './stats'


export function format
	lodash it
	.pick-by! # ignore empty values
	.map-values lodash.escape
	.map (val, key) ->
		"""
		<b>#key</b>:
		<pre>#{val.trim!}</pre>
		"""
	.join '\n\n'


export function execute [, lang, name, code, stdin]
	lang-id = langs[lang.to-lower-case!]
	if typeof lang-id != 'number'
		error = new Error "Unknown language: #lang."
		error.quiet = not name
		error.switch_pm_parameter = 'languages'
		return Promise.reject error

	request-promise do
		method: 'POST'
		url: 'http://rextester.com/rundotnet/api'
		form:
			LanguageChoice: lang-id
			Program: code
			Input: stdin
			CompilerArgs: compiler-args[lang-id] || ''
		json: true

	.promise!

	.tap -> stats.data.executions++


export function command cmd, args
	cmds = lodash(cmd)
		.cast-array!
		.join '|'
	space-and-args =
		if args
			"\\s+#args"
		else ''
	//^/#cmds(@#botname)?#space-and-args\s*$//i


export format-string = 'Ok, give me some %s code to execute'

export language-regex = '[\\w.#+]+'
