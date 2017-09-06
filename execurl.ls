'use strict'

require! 'bluebird': Promise
require! 'request-promise'

require! './constants': {
	execute
	language-regex
}
require! './objects': { respond }

export regex = //^
	/execurl(@#botname)?
	\s+(#language-regex)
	\s+(\S+)
	(?:\s+/stdin\s+([\s\S]+?))?
	\s*$//i

export function handler msg, match_
	var stdin
	var url
	[, name, lang, url, stdin] = match_
	if url != /^http/
		url = "http://#url"
	if match2 = url == //^https?:\/\/(?:www\.)?pastebin.com/(\w+)$//
		[, id] = match2
		url = "https://pastebin.com/raw/#id"
	stdin ?= msg.reply_to_message?.text
	request-promise.get(url)
	.then -> execute [, lang, name, it, stdin], msg.from.id
	|> respond(msg, _)
