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
	md: -> """
		Uptime: *#{new Duration @data.started-at .to-string!}*

		During that time, I executed *#{@data.executions}* snippets of code for *#{@data.users.size}* users.

		*#{@data.missing-source}* times users didn't supply source code.

		Version: *#{package_.version}*.
		"""
