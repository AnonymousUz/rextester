require!  {
	'./langs.json'
	'./emoji.json'
	'lodash'
}


tab = "\n\n#{emoji.bulb}Hit Tab instead of Enter to autocomplete command without sending it right away."

module.exports = (bot, botname) ->
	help-text = """Execute code.

	Usage: `/<language> <code> [/stdin <stdin>]`

	Inline mode:
	`@#botname <language> <code> [/stdin <stdin>]`

	Line breaks and indentation are supported.

	See list of supported programming /languages.
	"""

	bot.on-text //^[\/!]lang(uage)?s(@#botname)?\s*$//i, (msg) ->
		lodash langs
		.keys!
		.sortBy!
		.map -> "`#it`"
		.join ', '
		|> bot.send-message msg.chat.id, _,
			parse_mode: 'Markdown'


	bot.on-text //^/([\w.#+]+)(@#botname)?\s*$//i, (msg, [, command]) ->
		if command == 'help' or langs.has-own-property command.to-lower-case!
			bot.send-message do
				msg.chat.id
				# string.repeat bool <=> if bool then string else ""
				help-text + tab.repeat command != 'help'
				parse_mode: 'Markdown'
