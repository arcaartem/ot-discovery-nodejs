Promise = require "bluebird"
request = require "request"
url = require "url"

class DiscoveryWatcher
  constructor: () ->

  watch: (server, serviceType, index) =>
    query = {}
    query.since = index if index
    query.clientServiceType = serviceType if serviceType

    target = url.format
      protocol: 'http'
      host: server.replace /[h|H]\w+:\/\//, '' #remove http://, https://
      pathname: "watch"
      query: query
    # we have to hand promisify here so we can grab the request object
    # for aborting purposes
    new Promise (resolve, reject) =>
      @currentRequest = request
        url: target
        json: true
      , (err, response, body) ->
        if err
          reject err
        else
          resolve [response, body]
    .spread (response, body) =>
      @validateResponse response, body
    .finally () =>
      @currentRequest = null

  abort: () ->
    @currentRequest?.abort()
    
  validateResponse: (response, body) ->
    #bad status code
    if response.statusCode in [200, 204]
      return [response.statusCode, body]
    else
      error = new Error "Bad status code " + response.statusCode + " from watch: " + response
      throw error

module.exports = DiscoveryWatcher
