'use strict'

require! 'lodash'
require! 'scanf': {sscanf}
require! 'util'

require! './langs.json'
require! './stats'
require! './tips.ls'


format-string = 'Ok, give me some %s code to execute'

function format-tip tip
	if tip
		'\n' + tip
	else
		''


module.exports = (bot, botname, regex, reply) ->

	bot.on-text //^/cancel(@#botname)?\s*//i, (msg) ->
		bot.send-message do
			msg.chat.id
			'Cancelled'
			reply_to_message_id: msg.message_id
			reply_markup:
				remove_keyboard: true
				selective: true


	bot.on-text //^/([\w.#+]+)(@#botname)?\s*$//i, (msg, [, command, username]) ->
		language = command.to-lower-case! |> lodash.upper-first
		if langs.has-own-property command.to-lower-case!
			stats.data.missing-source++
			bot.send-message do
				msg.chat.id
				util.format format-string, language, format-tip tips.gimme-code!
				reply_to_message_id: msg.message_id
				reply_markup:
					force_reply: true
					selective: true
		else if username or msg.chat.type == 'private'
			bot.send-message do
				msg.chat.id
				"Unknown language: #language"
				reply_to_message_id: msg.message_id


	<- process.next-tick
	bot.on-text ////, (msg) ->
		reply-to = msg.reply_to_message
		if (reply-to and reply-to.from.username == botname
				and language = sscanf reply-to.text, format-string)
			text = "/#language #{msg.text}"
			reply msg with {text, _2part: true}, regex.exec text

		else if msg.chat.type == 'private'
			bot.send-message do
				msg.chat.id
				"Sorry, I couldn't understand that, do you need /help?"
