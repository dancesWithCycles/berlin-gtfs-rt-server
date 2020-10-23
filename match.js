'use strict'

const {pipeline, Transform} = require('stream')
const {parse, stringify} = require('ndjson')
const {POSITION, TRIP} = require('./lib/protocol')
const {matchTrip, stats} = require('./lib/match')

// todo: match positions as well
const transform = (item, _, cb) => {
	if (item[0] === TRIP) {
		const trip = item[1]

		matchTrip(trip)
		.then(trip => cb(null, [TRIP, trip]))
		// If matching failed, we still pass on the trip.
		.catch((err) => {
			console.error(err)
			cb(null, [TRIP, trip])
		})
		.catch(cb)
	} else {
		cb(null, item)
	}
}

pipeline(
	process.stdin,
	parse(),
	// todo: make transform parallel
	new Transform({
		objectMode: true,
		transform,
	}),
	stringify(),
	process.stdout,
	(err) => {
		if (!err) return;
		console.error(err)
		process.exit(1)
	},
)

setInterval(() => {
	console.error(stats())
}, 5000)
