'use strict'


answer = exports


answer.raw = (bot, query, results, options={}) ->
	inline_query_id = switch typeof query
	| 'number', 'string' => query
	| 'object' => query.id
	| otherwise throw new TypeError

	bot.answer-inline-query do
		inline_query_id
		results
		options


answer.empty = (bot, query, options) ->
	answer.raw bot, query, [], options


answer.switch-pm = (bot, query, switch_pm_text, switch_pm_parameter, options={}) ->
	answer.empty bot, query, ({switch_pm_text, switch_pm_parameter} <<< options)


answer.error = (bot, query, error, options) ->
	s = error.to-string!
	if error.switch_pm_parameter?
		answer.switch-pm bot, query, s, error.switch_pm_parameter
	else
		answer.single bot, query,
			type: 'article'
			id: 'error_'
			title: s
			description: error.description
			input_message_content:
				message_text: s


answer.single = (bot, query, article, options) ->
	answer.raw bot, query, [article], options
