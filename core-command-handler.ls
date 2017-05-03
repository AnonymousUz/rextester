'use strict'

require! 'lodash'

require! './objects': {
	respond
	responder
}
require! './constants': {execute}
require! './stats'

module.exports = (msg, match_) ->
	return if msg._handled
	msg._handled = true
	if verbose
		console.log msg
	execution = execute match_
	.tap ->
		[, Language, , Source, Stdin] = match_

		result = lodash.defaults {Language, Source, Stdin}, it

		responder.set msg, 'executionResults', result

	(execution
	|> respond msg, _,
		share: true
		tip: true
	).tap ->
		stats.data.by-type-of-query.text-msgs++
