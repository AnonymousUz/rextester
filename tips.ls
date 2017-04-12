'use strict'

require! 'lodash': _

require! './emoji.json'

exports.process-input = (msg) ->
	rand = Math.random!
	text-lower = msg.text.to-lower-case!
	switch
	| text-lower.starts-with '/php' and not text-lower.includes '<?php'
		=> "I think you meant to wrap your code in `<?php`, `?>` tags"
	| msg.entities?.1?.type not in ['pre', 'code'] and rand < 0.1
		=> "Wrap your code in triple backticks to display it in monospace."

exports.process-output = (o) ->
	rand = Math.random!
	switch
	| o.Result == "" and rand < 0.5
		=> "If you want to see the results of your code, I suggest printing them to stdout."
	| o.Errors or o.Result == ""
		=> "Mistake? Edit your message, I'll adjust my response."

gimmme-code-tips =
	'Send it as text, or pass a file'
	'Changed your mind? /cancel'
	...

exports.gimme-code = ->
	rand = Math.random!
	if rand < 0.4
		_.sample(gimmme-code-tips)
