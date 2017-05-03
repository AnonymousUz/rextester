'use strict'

require! {
	'bluebird': Promise
	'lodash'
	'./emoji.json'
}

module.exports = class Responder
	(@bot, @options) ->
		@msgs = {}
		if @options.ms-to-edit > 0
			set-interval do
				~> @msgs := lodash.pick-by @msgs, (.ttl -= 1)
				@options.ms-to-edit

	_get-context: (msg) ->
		@msgs[[msg.chat.id, msg.message_id]] ?= {ttl: 2}

	set: (msg, key, value) ->
		context = @_get-context msg
		context[key] = value

	get: (msg, key) ->
		context = @_get-context msg
		Promise.resolve context[key]

	_respond: (msg, reply, content, options) ->
		s = content.to-string!
		context = @_get-context msg
		(reply || Promise.reject!)
		.then (old-msg) ~>
			@bot.edit-message-text do
				s
				lodash.assign do
					chat_id: old-msg.chat.id
					message_id: old-msg.message_id
					options
		.catch ~>
			if not content.quiet or msg.chat.type == 'private'
				context.reply = @bot.send-message do
					msg.chat.id
					s
					lodash.assign do
						reply_to_message_id: msg.message_id
						options


	preparing-response-to: (msg) ->
		context = @_get-context msg

		reply = context.reply

		context.typing =
			if reply
				reply.then (old-msg) ~>
					@bot.edit-message-text do
						"#{emoji.hourglass}Processing your edit..."
						chat_id: old-msg.chat.id
						message_id: old-msg.message_id
			else
				@bot.send-chat-action msg.chat.id, 'typing'


	respond-object: (msg, promise, err-options) ->
		context = @_get-context msg

		context.edit?.cancel!
		context.reply = null if context.reply?.is-rejected!

		reply = context.reply

		process = Promise.resolve(promise)
		.then ({res-options, res}) ~>
			@_respond msg, reply, res, res-options
		.catch  (err) ~> @_respond msg, reply, err, err-options

		if context.reply?
			context.edit  = process
		else
			context.reply = process


	respond-when-ready: (msg, promise, res-options, err-options) ->
		context = @_get-context msg

		context.edit?.cancel!
		context.reply = null if context.reply?.is-rejected!

		reply = context.reply

		process = Promise.join do
			promise
			context.typing?.reflect!
		.spread (res) ~> @_respond msg, reply, res, res-options
		.catch  (err) ~> @_respond msg, reply, err, err-options

		if context.reply?
			context.edit  = process
		else
			context.reply = process
