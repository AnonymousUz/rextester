'use strict'

require! 'language-detect'
require! 'request-promise'
require! 'scanf': {sscanf}

require! './constants': {
	execute
	format-string
}
require! './objects': {
	bot
	respond
}


module.exports = (msg) ->
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
