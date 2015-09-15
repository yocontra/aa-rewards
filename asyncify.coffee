async = require 'async'

module.exports = (o, cb) ->
  asyncRecurse = (obj) ->
    n = {}
    for k, v of obj
      if typeof v is 'function'
        n[k] = v
      else
        n[k] = async.parallel.bind null, asyncRecurse v
    return n

  return async.parallelLimit asyncRecurse(o), 1, cb
