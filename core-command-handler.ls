'use strict'

require! './objects': {respond}
require! './constants': {execute}

module.exports = (msg, match_) ->
	return if msg._handled
	msg._handled = true
	if verbose
		console.log msg
	execution = execute match_

	execution
	|> respond msg, _,
		share: true
		tip: true
