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
	'./answer'
	'./exec-stats'
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


options =
	only-first-match: true
	request:
		transform: (body, request) ->
			if not body
				request.body = request.status-message
			else
				data = JSON.parse body
				if not data.ok
					request.body = data.description
			return request

options <<<
	if url?
		web-hook:
			host: '0.0.0.0'
			port: process.env.PORT || 8000
	else
		polling : true

bot = new Bot token, options

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
		return answer.empty bot, query

	match_ = regex.exec '/' + query.query

	console.log match_ if verbose and match_

	if not match_
		return answer.switch-pm bot, query, "Invalid query syntax", ''

	execution = execute match_

	execution
	.then (raw) ->
		[, Language, , Source, Stdin] = match_

		exec-stats_ = exec-stats.compress raw.Stats
		delete raw.Stats

		result = lodash.defaults {Language, Source, Stdin}, raw
		|> format

		answer.single bot, query, {
			type: 'article'
			id: 'test'
			title: raw.Errors || raw.Result || "Did you forget to output something?"
			input_message_content:
				message_text: result
				parse_mode: 'Markdown'
			reply_markup: inline_keyboard:
				[
					text: 'See stats'
					callback_data: "showExecStats\n#exec-stats_"
				]
				...
		}, cache_time: 0

	.catch (error) -> answer.error bot, query, error
	.tap ->
		stats.data.users.add query.from.id

reply = (msg, match_) ->
	if verbose
		console.log msg
	execution = execute match_

	responder.preparing-response-to msg if execution.is-pending!

	var exec-stats_

	process = execution
	.tap ->
		exec-stats_ := exec-stats.compress it.Stats
		delete it.Stats
		it.Tip = tips.process-output it or tips.process-input msg
		stats.data.users.add msg.from.id
	.then format

	process.suppress-unhandled-rejections!

	process.finally ->
		responder.respond-when-ready msg, process,
			parse_mode: 'Markdown'
			reply_markup: inline_keyboard:
				[
					text: 'See stats'
					callback_data: "showExecStats\n#exec-stats_"
				]
				[
					text: 'Share'
					switch_inline_query: msg.text.slice 1
				]
				...


bot.on 'callback_query', (query) ->
	[action, ...data] = query.data.split '\n'

	switch action
		case 'showExecStats'
			bot.answer-callback-query do
				query.id
				exec-stats.restore data
				true
				cache_time: 604800 # 1 week


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
