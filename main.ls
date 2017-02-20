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
	'./gimme-code'
	'language-detect'
	'scanf': {sscanf}
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


bot = new Bot token, options

responder = new Responder bot, {
	ms-to-edit: secs-to-edit * 1000
}

function run-async generator
	Promise.coroutine(generator)!

*<- run-async
me = yield bot.get-me!

botname = me.username

help bot, botname

function format
	lodash it
	.pickBy! # ignore empty values
	.map-values lodash.escape
	.map (val, key) ->
		"""
		<b>#key</b>:
		<pre>#{val.trim!}</pre>
		"""
	.join '\n\n'

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
				parse_mode: 'HTML'
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
	return if msg._handled
	msg._handled = true
	if verbose
		console.log msg
	execution = execute match_


	execution
	|> respond msg, _,
		share: true
		tip: true


function respond msg, execution, options = {}
	need-remove-keyboard = msg._2part and not msg._edit

	if execution.is-pending!
		# fails when message we were trying to edit has remove_keyboard
		responder.preparing-response-to msg
		# .suppressUnhandledRejections didn't work here
		.catch lodash.noop

	remove_keyboard =
		remove_keyboard: true
		selective: true

	err-options = reply_markup: remove_keyboard


	process = execution
	.then ->
		exec-stats_ = exec-stats.compress it.Stats
		delete it.Stats
		it.Tip = tips.process-output it or tips.process-input msg if options.tip
		stats.data.users.add msg.from.id
		buttons = [
			[
				text: 'See stats'
				callback_data: "showExecStats\n#exec-stats_"
			]
		]

		if options.share
			buttons.push [
				text: 'Share'
				switch_inline_query: msg.text.slice 1
			]

		return
			res: format it
			res-options:
				parse_mode: 'HTML'
				reply_markup:
					if need-remove-keyboard
						remove_keyboard
					else
						inline_keyboard: buttons

	|> responder.respond-object msg, _, err-options



bot.on 'callback_query', (query) ->
	[action, ...data] = query.data.split '\n'

	switch action
		case 'showExecStats'
			bot.answer-callback-query do
				query.id
				exec-stats.restore data
				true
				cache_time: 604800 # 1 week

gimme-code bot, botname, regex, reply

bot.on-text regex, reply

bot.on 'edited_message_text', (msg) ->
	msg._edit = true
	bot.process-update message: msg

format-string = 'Ok, give me some %s code to execute'

bot.on 'document', (msg) ->
	reply-to = msg.reply_to_message

	if ((reply-to and reply-to.from.username == botname
			and language = sscanf reply-to.text, format-string)

			or msg.chat.type == 'private')

		file_name = msg.document.file_name

		bot.get-file-link msg.document.file_id
		.then request-promise.get
		.then (code) ->
			lang = language || language-detect.contents file_name, code
			execute [, lang, , code]
		|> respond msg, _



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
	yield bot.open-web-hook!
	yield bot.set-web-hook "#url/#token"
else
	yield bot.start-polling!

console.info 'Bot started.'
