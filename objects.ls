'use strict'

require! 'node-telegram-bot-api': 'Bot'

require! './constants': {
	execute
	format
}
require! './exec-stats'
require! './responder': Responder
require! './tips'
require! './stats'

token = process.env.TELEGRAM_BOT_TOKEN || require './token.json'

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


export bot = new Bot token, options

export promise-me = bot.get-me!

export responder = new Responder bot, {
	ms-to-edit: secs-to-edit * 1000
}


export function respond msg, execution, options = {}
	need-remove-keyboard = msg._2part and not msg._edit

	if execution.is-pending!
		# fails when message we were trying to edit has remove_keyboard
		responder.preparing-response-to msg
		# .suppressUnhandledRejections didn't work here
		.catch-return!

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
			if msg.chat.type == 'private'
				buttons.push [
					text: 'Share'
					switch_inline_query: '/share ' + msg.message_id
				]
			else
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
