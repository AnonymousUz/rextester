require!  {
	'./langs.json'
	'./emoji.json'
	'lodash'
	'./package.json'
	'./stats'
}


tab = "\n\n#{emoji.bulb}Hit Tab instead of Enter to autocomplete command without sending it right away."

module.exports = (bot, botname) ->
	help-text = """Execute code.

	Usage: `/<language> <code> [/stdin <stdin>]`

	Inline mode:
	`@#botname <language> <code> [/stdin <stdin>]`

	Line breaks and indentation are supported.

	I'll also try to execute files pm'ed to me.

	See list of supported programming /languages.
	See /about for useful links.
	"""
	bot.on-text //^/(start\s+)?lang(uage)?s(@#botname)?\s*$//i, (msg) ->
		lodash langs
		.keys!
		.sortBy!
		.map -> "`#it`"
		.join ', '
		|> bot.send-message msg.chat.id, _,
			parse_mode: 'Markdown'


	bot.on-text //^/about(@#botname)?\s*$//i, (msg) ->
		bot.send-message do
			msg.chat.id
			"""
			Created by @GingerPlusPlus.

			Note that the bot uses rextester.com to execute code.
			"""
			parse_mode: 'Markdown'
			disable_web_page_preview: true
			reply_markup: inline_keyboard:
				[
					{
						text: "Official group"
						url: "telegram.me/Rextesters"
					} {
						text: "Repository"
						url: ``package``.repository.url
					} {
						text: "Rate"
						url: "https://telegram.me/storebot?start=#botname"
					}
				]
				...


	bot.on-text //^/stat(istic)?s(@#botname)?\s*$//i, (msg) ->
		bot.send-message do
			msg.chat.id
			stats.md!
			parse_mode: 'Markdown'


	bot.on-text //^/(help|start)(@#botname)?\s*$//i, (msg, [, command]) ->
		bot.send-message do
			msg.chat.id
			help-text
			parse_mode: 'Markdown'
