#!./node_modules/.bin/lsc

require! {
	'node-telegram-bot-api': 'Bot'
	'request-promise'
	'lodash'
	'bluebird': 'Promise'
	'./langs.json'
	'./compiler-args.json'
	'./help'
	'./tips'
	'./emoji.json'
	'./stats'
	'./responder': 'Responder'
}

Promise.config do
	cancellation: true

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

verbose = lodash process.argv
	.slice 2
	.some -> it == '-v' or it == '--verbose'

url = process.env.NOW_URL

secs-to-edit = process.env.SECS_TO_EDIT

if secs-to-edit == void
	console.warn "SECS_TO_EDIT unspecified, more details in README."


bot = new Bot token,
	if url?
		web-hook:
			host: '0.0.0.0'
			port: process.env.PORT || 8000
		only-first-match: true
	else
		polling : true
		only-first-match: true

responder = new Responder bot, {
	ms-to-edit: secs-to-edit * 1000
}

(me) <- bot.get-me!.then

botname = me.username

help bot, botname

function format
	lodash it
	.pickBy! # ignore empty values
	.map (val, key) ->
		"""
		*#key*: ```
		#{val.trim!}
		```
		"""
	.join '\n'

regex = //^/
	([\w.#+]+) # language
	(?:@(#botname))?
	\s+
	([\s\S]+?) # code
	(?:
		\s+
		/stdin
		\s+
		([\s\S]+) # stdin
	)?
$//i

bot.on 'inline_query', (query) ->
	console.log query if verbose

	if not query.query
		return bot.answer-inline-query do
			query.id
			[]
			inline_query_id: query.id

	match_ = regex.exec '/' + query.query

	console.log match_ if verbose and match_

	execution =
		if match_
			execute match_
		else
			error = new Error "Invalid query syntax."
			error.description = "It's <language> <code> [/stdin <stdin>]"
			error.switch_pm_parameter = ''
			Promise.reject error

	execution
	.then (raw) ->
		result = lodash.defaults do
			Language: match_[1]
			Source: match_[3]
			Stdin: match_[4]
			raw
		|> format

		bot.answer-inline-query do
			query.id
			[{
				id: 'test'
				type: 'article'
				title: raw.Errors || raw.Result  || "Did you forget to output something?"
				input_message_content:
					message_text: result
					parse_mode: 'Markdown'

			}]
			cache_time: 0
			inline_query_id: query.id
	.catch (e) ->
		s = e.to-string!
		if e.switch_pm_parameter?
			bot.answer-inline-query do
				query.id
				[]
				inline_query_id: query.id
				switch_pm_parameter: e.switch_pm_parameter
				switch_pm_text: s
		else
			bot.answer-inline-query do
				query.id
				[{
					id: 'test'
					type: 'article'
					title: s
					description: e.description
					input_message_content:
						message_text: s
				}]
				inline_query_id: query.id
	.tap ->
		stats.data.users.add query.from.id

reply = (msg, match_) ->
	if verbose
		console.log msg
	execution = execute match_

	responder.preparing-response-to msg if execution.is-pending!

	execution
	.tap ->
		it.Tip = tips.process-output it or tips.process-input msg
		stats.data.users.add msg.from.id
	.then format
	|> responder.respond-when-ready msg, _, parse_mode: 'Markdown'


bot.on-text regex, reply

bot.on 'edited_message_text', (msg) ->
	match_ = regex.exec msg.text
	if not match_
		return

	reply msg, match_


function execute [, lang, name, code, stdin]
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


if url?
	bot.set-web-hook "#url/#token"

console.info 'Bot started.'
