'use strict'

require! 'lodash'
require! 'request-promise'

require! './answer'
require! './compiler-args.json'
require! './constants': {
	execute
	format
}
require! './exec-stats'
require! './objects': {
	bot
	responder
}
require! './stats'

commands =
	share: (query, message_id) ->
		uid = query.from.id

		responder.get do
			{message_id, chat:id: uid}
			'executionResults'
		.then (raw) ->
			if not raw
				return answer.switch-pm bot, query, 'run it again', "reexec#message_id",
					is_personal: true
					cache_time: 0
			result = format raw

			exec-stats_ = exec-stats.compress raw.Stats
			delete raw.Stats

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
			}, {
				cache_time: 0
				is_personal: true
			}



module.exports = (query) ->
	if not query.query
		return answer.empty bot, query

	if command-match = query.query == //^/(\w+)\s+([\s\S]+?)\s*$//i
		[, command, arg] = command-match
		return if commands[command.to-lower-case!]?(query, arg)

	match_ = regex.exec '/' + query.query

	if not match_
		return answer.switch-pm bot, query, "Invalid query syntax", 'help'

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

	.tap ->
		stats.data.by-type-of-query.inline++
	.catch (error) -> answer.error bot, query, error
	.tap ->
		stats.data.users.add query.from.id
