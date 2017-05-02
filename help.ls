'use strict'

require!  {
	'./langs.json'
	'./emoji.json'
	'lodash'
	'./objects': {bot}
	'./package.json': package_
	'./stats'
	'./redis'
}


help-text = """Execute code.

Usage: `/<language> <code> [/stdin <stdin>]`

Inline mode:
`@#botname <language> <code> [/stdin <stdin>]`

Line breaks and indentation are supported.

I'll also try to execute files pm'ed to me.

See list of supported programming /languages.
See /about for useful links.
"""

export send-langs = (msg) ->
	lodash langs
	.keys!
	.sort-by!
	.map ->
		if msg.chat.type == 'private' and it == /^\w+$/
			"/#it"
		else
			"<code>/#it</code>"
	.join ', '
	|> bot.send-message msg.chat.id, _,
		parse_mode: 'HTML'
		reply_markup: inline_keyboard: [[
			text: 'Customize...'
			url: "t.me/#botname?start=alias"
		]] if redis


export about = (msg) ->
	bot.send-message do
		msg.chat.id
		"""
		Created by @GingerPlusPlus, powered by rextester.com.
		"""
		disable_web_page_preview: true
		reply_markup: inline_keyboard:
			[
				{
					text: "Official group"
					url: "telegram.me/Rextesters"
				} {
					text: "Repository"
					url: package_.repository.url
				} {
					text: "Rate"
					url: "https://telegram.me/storebot?start=#botname"
				}
			]
			...


export send-stats = (msg) ->
	bot.send-message do
		msg.chat.id
		stats.md!
		parse_mode: 'Markdown'



export help = (msg) ->
	bot.send-message do
		msg.chat.id
		help-text
		parse_mode: 'Markdown'
