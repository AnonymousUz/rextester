'use strict'

url = process.env.REDIS_URL


if url
	console.info 'REDIS_URL present, connecting to database...'
	require! 'ioredis': Redis
	module.exports = new Redis(url)
else
	console.info 'REDIS_URL absent, running without database.'
	module.exports = null
