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


export execute = Promise.coroutine ([, lang, name, code, stdin], uid) ->*
	lang-obj = yield alias.resolve uid, lang

	switch lang-obj.type
	| 'nothing'
		error = new Error "Unknown language: #lang."
		error.quiet = not name
		error.switch_pm_parameter = 'languages'
		return Promise.reject error
	| 'choice', 'unambiguous'
		possibilities = lang-obj.resolved
		lang-id = langs[possibilities[0]]
	| 'resolved'
		lang-id = lang-obj.resolved
	| otherwise throw new Error 'wtf'

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

	.tap ->
		if lang-obj.type == 'choice'
			it.Note = "#{possibilities[0]} assumed, run `/alias #lang` to tell me what #lang means for you."
		else if lang-obj.type == 'unambiguous'
			possibilities-string = possibilities.slice(1).join(', ')
			option-is-or-options-are =
				if possibilities.length > 2
					"options are"
				else
					"option is"
			it.Note = "#{possibilities[0]} assumed, " +
				"other valid #option-is-or-options-are #possibilities-string" +
				", you can be more specific next time."
		stats.data.executions++
		stats.data.with-stdin++ if stdin


export function command cmd, args, options={}
	cmds = lodash(cmd)
		.cast-array!
		.join '|'
	space-and-args =
		if args and options.args-are-optional
			"(?:\\s+#args)?"
		else if args
			"\\s+#args"
		else ''
	//^/#cmds(@#botname)?#space-and-args\s*$//i


export format-string = 'Ok, give me some %s code to execute'

export language-regex = '[\\w.#+]+'

# require cycle ._.
require! './alias'
