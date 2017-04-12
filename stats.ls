'use strict'

require! {
	'duration': 'Duration'
	'./package.json': package_
}

module.exports =
	data:
		executions: 0
		started-at: new Date
		users: new Set
		missing-source: 0
		with-stdin: 0
		by-type-of-query:
			inline: 0
			documents: 0
			text-msgs: 0
	md: -> """
		Uptime: *#{new Duration @data.started-at .to-string!}*

		Users: *#{@data.users.size}*

		*#{@data.executions}* successfully executed code requests:
		» *#{@data.by-type-of-query.text-msgs}* via text messages
		(includes *#{@data.missing-source}* two-parts, and edits)
		» *#{@data.by-type-of-query.inline}* via inline queries
		» *#{@data.by-type-of-query.documents}* via documents (files)

		*#{@data.with-stdin}* of the requests used a non-empty stdin.

		Version: *#{package_.version}*.
		"""
