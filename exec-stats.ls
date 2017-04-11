'use strict'

require! 'lodash': _

to-longer =
	c: 'compilation time'
	r: 'absolute running time'
	C: 'cpu time'
	m: 'memory peak'
	M: 'average memory usage'
	T: 'average nr of threads'
	t: 'absolute service time'

to-shorter = _.invert to-longer


export function compress s
	_ s
	.split(', ')
	.map (.split ': ')
	.from-pairs!
	.map-keys (v, k) ->
		to-shorter[k.to-lower-case!]
	.omit 'undefined'
	.map (v, k) -> "#k#v"
	.join '\n'


export function restore s
	_ s
	.map -> [it[0], it.slice(1)]
	.from-pairs!
	.map-keys (v, k) ->
		to-longer[k]
	.map (v, k) ->
		"#k: #v"
	.join '\n'
