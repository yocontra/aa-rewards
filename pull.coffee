async = require 'async'
request = require 'superagent'
moment = require 'moment'
asyncify = require './asyncify'
airports = require './airports'

cabins = [
  'economy'
  'premium'
]
regions = [
  'domestic'
  'hawaii'
  'canada_alaska'
  'mexico_caribbean'
  'central_south_america'
  'europe'
  'asia_pacific_australia'
  'africa_middle_east'
]

reqs = 0
makeRequestFn = (airport, cabinType, region, opt={}) ->
  ++reqs
  return (done) ->
    request.get 'http://www.aa.com/awardMap/api/search'
      .set 'Accept', 'application/json'
      .query
        destination: opt.destination
        origin: airport.code
        category: region.toUpperCase()
        cabin: cabinType.toUpperCase()
        departureMinDate: moment(opt.departure).format('MM/DD/YYYY')
        returnMinDate: moment(opt.return).format('MM/DD/YYYY')
        roundTrip: opt.roundTrip or true
        pax: 1
        miles: '100,000,000'
        maxStopCount: 100
        includePartners: true
      .end (err, res) ->
        return makeRequestFn(airport, cabinType, region, opt)(done) if err? or !res?
        done err, res?.body

makeRequestObj = (opt={}) ->
  o = {}
  for airport in airports when airport.code is opt.airport
    o[airport.code] = {}
    for cabinType in cabins
      o[airport.code][cabinType] = {}
      for region in regions
        o[airport.code][cabinType][region] = makeRequestFn airport, cabinType, region, opt
  return o

tasks = makeRequestObj
  airport: 'SFO'
  departure: new Date '12/15/2015'
  return: new Date '12/22/2015'

console.log 'Sending', reqs, 'requests...'
asyncify tasks, (err, res) ->
  return console.error err if err?
  console.log res
  require('fs').writeFileSync 'results.json', JSON.stringify res, null, 2
