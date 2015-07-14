Promise        = require "bluebird"
Errors         = require "./Errors"
RequestPromise = require "./RequestPromise"
Utils          = require "./Utils"

class DiscoveryConnector

  constructor:(@host, @logger, @discoveryNotifier)->
    @CONNECT_ATTEMPTS = 100
    @INITIAL_BACKOFF = 500

  connectUrl:()->
    "http://#{@host}/watch"

  connect:()->
    Utils.promiseRetry(
      @attemptConnect
      @CONNECT_ATTEMPTS
      @INITIAL_BACKOFF
    )

  attemptConnect:()=>
    url = @connectUrl()
    @logger.log("debug", "Attempting connection to #{url}")

    RequestPromise(url:url, json:true)
      .catch(@discoveryNotifier.notifyAndReject)
      .then(@handle)

  handle:(response)=>
    if response.statusCode != 200
      return @discoveryNotifier.notifyAndReject(
        new Errors.DiscoveryConnectError(response.body))

    update = response.body

    unless update?.fullUpdate
      return @discoveryNotifier.notifyAndReject(
        new Errors.DiscoveryFullUpdateError(update))

    @logger.log 'debug', 'Discovery update: ' + JSON.stringify(update)

    return update

module.exports = DiscoveryConnector