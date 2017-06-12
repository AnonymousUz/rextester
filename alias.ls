'use strict'

require! './langs.json'
require! './redis'

require! 'bluebird': Promise
require! 'lodash'
require! 'util'

aliases-format = "user%s:aliases"

collect-alias-stats = process.env.ALIAS_STATS?
if collect-alias-stats
	if redis
		console.log 'ALIAS_STATS enabled, see Readme.'
	else
		console.error 'ALIAS_STATS requested, but Redis is not available! Set REDIS_URL.'

max-number-of-aliases-per-user = process.env.MAX_ALIASES_PER_USER || 30
max-alias-length = process.env.MAX_ALIAS_LENGTH || 32

inverted-by = lodash.invert-by langs
inverted = lodash.map-values inverted-by, lodash.head


function to-string
	other-name = inverted[@resolved]
	"""*#{@lower}*
	→ #{@resolved || ':nothing'}""" + " (*#other-name*)".repeat(other-name?)

function follow-hardlink lang-query
	lower = lang-query.to-lower-case!
	if typeof langs[lower] == 'string'
		langs[lower]
	else
		lower

function resolve-identity lang-query
	{
		lang-query: lang-query
		resolved: lang-query
		type: 'resolved'
		to-string
	}


export resolve =  Promise.coroutine (uid, lang-query, options={}) ->*
	lower = follow-hardlink(lang-query)
	if redis and uid
		custom = yield redis.hget util.format(aliases-format, uid), lower
	if redis and collect-alias-stats and lower.length <= max-alias-length
		redis.hincrby 'alias-stats', lang-query.to-lower-case!, 1
	default_ = langs[lower]
	
	if Array.is-array default_
		default_.to-string = ->
			@map -> "*#it*"
			.join ' or '

	resolved = 
		if custom == ':nothing'
			void
		else
			custom or default_

	type =
		if not resolved?
			'nothing'
		else if Array.is-array resolved
			if redis
				'choice'
			else
				'unambiguous'
		else if typeof resolved in ['number', 'string']
			'resolved'
		else
			throw new Error 'wtf'

	return {
		choice-keyboard
		custom
		default_
		lang-query
		lower
		resolved
		type
		to-string
	}


display-alias = Promise.coroutine (msg, alias, options={}) ->*
	lang-query-obj = yield resolve(msg.from.id, alias)
	suggestions =
		| not redis or not options.suggestions
			[]
		| Array.is-array lang-query-obj.default_
			lang-query-obj.default_
		| lang-query-obj.custom == ':nothing'
			[':default']
		| lang-query-obj.resolved == lang-query-obj.custom and lang-query-obj.default_
			[':default']
		| otherwise
			[]

	bot.send-message do
		msg.chat.id
		lang-query-obj.to-string!
		parse_mode: 'Markdown'
		reply_markup:
			if suggestions.length
				inline_keyboard: [suggestions.map (text) ->
					if String(langs[text]) == lang-query-obj.resolved => {
						text: "#text (current)"
						callback_data: "noop"
					} else {
						text:
							if suggestions.length == 1
								"Set to #text"
							else
								text
						callback_data: """
							setAlias #alias #text

							displayAliasHere #alias
						"""
					}
				]


export set = Promise.coroutine (uid, _dest, _src) ->*
	dest = follow-hardlink _dest
	if dest.length > max-alias-length
		throw new Error "Alias name too long"
	src = _src.to-lower-case!
	user-string = util.format aliases-format, uid
	if src == ':default'
		yield redis.hdel user-string, dest
		return
	number-of-aliases = yield redis.hlen user-string
	if number-of-aliases >= max-number-of-aliases-per-user
		throw new Error do
			"
				You have reached the limit of user-defined aliases (#max-number-of-aliases-per-user). 
				Set some of your #number-of-aliases aliases to :default and try again.
			"
	lang-query-obj =
		if src == ':nothing' or src == /^\d+$/
			console.log 'id'
			resolve-identity src
		else
			yield resolve uid, src
	if lang-query-obj.type == 'resolved'
		yield redis.hset do
			user-string
			dest
			lang-query-obj.resolved
	else
		switch lang-query-obj.type
		| 'nothing' => throw new Error "I don't know what *#src* is"
		| 'choice'  =>
			error = new Error "*#src* can refer to #{lang-query-obj.resolved} -- which one do you mean?"
			error.reply_markup = inline_keyboard:
				[lang-query-obj.resolved.map (text) -> {
					text
					callback_data: """
					setAlias #_dest #text

					displayAliasHere #_dest
					"""
				}]
			throw error
		| otherwise => throw new Error "This should never happen."


export handler = Promise.coroutine (msg, [, name, arg='']) ->*
	if match_ = arg == //^#{language-regex}$//
		[alias] = match_
		display-alias msg, alias, suggestions: true
	else if not redis
		bot.send-message do
			msg.chat.id
			'Not available, not connected to Redis'
	else if match_ = arg == //(#language-regex)\s*=\s*(\:?#language-regex)//
		[, _dest, _src] = match_
		set msg.from.id, _dest, _src
		.then  -> display-alias msg, _dest
		.catch -> bot.send-message do
			msg.chat.id
			it.to-string!
			parse_mode: 'Markdown'
			reply_markup: it.reply_markup
	else
		bot.send-message do
			msg.chat.id
			"""
				`/alias <alias>` — see what `<alias>` currently means.

				`/alias <alias>=<src>` — make `<alias>` mean `<src>`.
				`<src>` can be another alias, [numerical id](rextester.com/Main), `:default`, `:nothing`.

				Aliases must match `/#language-regex/`.
			"""
			parse_mode: 'Markdown'	
			disable_web_page_preview: true		

# require cycle ._.
require! './constants': {language-regex}
require! './objects': {bot}
