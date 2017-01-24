exports.process-input = (msg) ->
	rand = Math.random!
	switch
	| msg.entities.1?.type not in ['pre', 'code'] and rand < 0.1
		=> "Wrap your code in triple backticks to display it in monospace."

exports.process-output = (o) ->
	| o.Errors or o.Result == ""
		=> "Mistake? Edit your message, I'll adjust my response."
