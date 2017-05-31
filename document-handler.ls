'use strict'

require! 'language-detect'
require! 'request-promise'

require! './constants': {
	execute
	format-string
	regex2part
}
require! './objects': {
	bot
	respond
}
require! './stats'


module.exports = (msg) ->
	reply-to = msg.reply_to_message

	if ((reply-to and reply-to.from.username == botname
			and language = language = regex2part.exec(reply-to.text)?[1])

			or msg.chat.type == 'private')

		file_name = msg.document.file_name

		(bot.get-file-link msg.document.file_id
		.then request-promise.get
		.then (code) ->
			lang = language || language-detect.contents file_name, code
			execute [, lang, , code], msg.from.id
		.then -> respond msg, it
		).tap ->
			stats.data.by-type-of-query.documents++
