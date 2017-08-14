'use strict'

require! './objects': {
	typing
	respond
}
require! './constants': {execute}
require! './stats'

module.exports = (msg, match_) ->
	return if msg._handled
	msg._handled = true
	if verbose
		console.log msg
	execution = execute match_, msg.from.id, typing(msg)

	(execution
	|> respond msg, _,
		share: true
		tip: true
	).tap ->
		stats.data.by-type-of-query.text-msgs++
