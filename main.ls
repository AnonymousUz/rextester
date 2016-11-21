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
}

Promise.config do
	cancellation: true

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

verbose = lodash process.argv
	.slice 2
	.some -> it == '-v' or it == '--verbose'

url = process.env.NOW_URL

msgs = {}

secs-to-edit = process.env.SECS_TO_EDIT

if secs-to-edit == void
	console.warn "SECS_TO_EDIT unspecified, more details in README."


if secs-to-edit > 0
	set-interval do
		-> msgs := lodash.pick-by msgs, (.ttl -= 1)
		secs-to-edit * 1000


bot = new Bot token,
	if url?
		web-hook:
			host: '0.0.0.0'
			port: process.env.PORT || 8000
		only-first-match: true
	else
		polling : true
		only-first-match: true

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

reply = (msg, match_) ->
	if verbose
		console.log msg
	execution = execute match_
	bot.send-chat-action msg.chat.id, 'typing' unless execution.is-rejected!
	reply = execution
	.tap ->
		it.Tip = tips.process-output it or tips.process-input msg
	.then format
	.then (result) ->
		bot.send-message do
			msg.chat.id
			result
			reply_to_message_id: msg.message_id
			parse_mode: 'Markdown'
	.catch quiet: true, -> throw it if msg.chat.type == 'private'
	.catch (e) ->
		bot.send-message do
			msg.chat.id
			e.to-string!
			reply_to_message_id: msg.message_id
	msgs[[msg.chat.id, msg.message_id]] = {reply, ttl: 2} unless execution.is-rejected!

bot.on-text regex, reply

bot.on 'edited_message_text', (msg) ->
	match_ = regex.exec msg.text
	if not match_
		return

	context = msgs[[msg.chat.id, msg.message_id]]
	if not context or context.reply.is-rejected!
		return reply msg, match_

	context.edit?.cancel!


	execution = execute match_
		.tap ->
			it.Tip = tips.process-output it or tips.process-input msg
		.then format

	processing = context.reply.then (old-msg) ->
		if execution.is-pending!
			bot.edit-message-text do
				"#{emoji.hourglass}Processing your edit..."
				chat_id: old-msg.chat.id
				message_id: old-msg.message_id

	context.edit = Promise.join context.reply, execution, processing.catch-return!
		.spread (old-msg, result) ->
			bot.edit-message-text do
				result
				chat_id: old-msg.chat.id
				message_id: old-msg.message_id
				parse_mode: 'Markdown'
			.catch ->
				msgs[[msg.chat.id, msg.message_id]] =
					reply: bot.send-message do
						msg.chat.id
						result
						reply_to_message_id: msg.message_id
						parse_mode: 'Markdown'
		.catch (e) ->
			processing.then (old-msg) ->
				bot.edit-message-text do
					e.to-string!
					chat_id: old-msg.chat.id
					message_id: old-msg.message_id
			.catch ->
				msgs[[msg.chat.id, msg.message_id]] =
					reply: bot.send-message do
						msg.chat.id
						e.to-string!
						reply_to_message_id: msg.message_id


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


if url?
	bot.set-web-hook "#url/#token"

console.info 'Bot started.'
