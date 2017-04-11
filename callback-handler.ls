'use strict'

require! './objects': {bot}
require! './exec-stats'

module.exports = (query) ->
	[action, ...data] = query.data.split '\n'

	switch action
		case 'showExecStats'
			bot.answer-callback-query do
				query.id
				exec-stats.restore data
				true # show-alert
				cache_time: 604800 # 1 week
