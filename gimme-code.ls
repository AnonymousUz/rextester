'use strict'

require! 'lodash'
require! 'scanf': {sscanf}
require! 'util'

require! './langs.json'
require! './stats'


format-string = 'Ok, give me some %s code to execute'

module.exports = (bot, botname, regex, reply) ->

	bot.on-text //^/([\w.#+]+)(@#botname)?\s*$//i, (msg, [, command, username]) ->
		language = command.to-lower-case! |> lodash.upper-first
		if langs.has-own-property command.to-lower-case!
			stats.data.missing-source++
			bot.send-message do
				msg.chat.id
				util.format format-string, language
				parse_mode: 'Markdown'
				reply_to_message_id: msg.message_id
				reply_markup:
					force_reply: true
					selective: true
		else if username or msg.chat.type == 'private'
			bot.send-message do
				msg.chat.id
				"Unknown language: #language"
				reply_to_message_id: msg.message_id


	bot.on 'text', (msg) ->
		reply-to = msg.reply_to_message
		if (reply-to and reply-to.from.username == botname
				and language = sscanf reply-to.text, format-string)
			text = "/#language #{msg.text}"
			reply msg with {text}, regex.exec text
