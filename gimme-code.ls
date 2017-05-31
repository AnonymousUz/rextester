'use strict'

require! 'lodash'
require! 'util'

require! './core-command-handler'
require! './constants': {
	format-string
	regex2part
}
require! './langs.json'
require! './objects': {
	bot
}
require! './stats'
require! './tips'


function format-tip tip
	if tip
		'\n' + tip
	else
		''



export function cancel(msg)
	bot.send-message do
		msg.chat.id
		'Cancelled'
		reply_to_message_id: msg.message_id
		reply_markup:
			remove_keyboard: true
			selective: true


export function missing-source(msg, [, command, username])
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


export function anything(msg)
	reply-to = msg.reply_to_message
	if (reply-to and reply-to.from.username == botname
			and language = regex2part.exec(reply-to.text)?[1])
		text = "/#language #{msg.text}"
		core-command-handler msg with {text, _2part: true}, regex.exec text

	else if msg.chat.type == 'private'
		bot.send-message do
			msg.chat.id
			"Sorry, I couldn't understand that, do you need /help?"
