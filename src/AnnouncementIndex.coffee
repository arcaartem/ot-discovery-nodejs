_ = require "lodash"

class AnnouncementIndex

  constructor: () ->
    #use the getter... not the direct private member!
    @_announcements = {}

    @discoveryServers = []
    @index = -1

  processUpdate: (update) ->
    if update.fullUpdate
      @clearAnnouncements()

    @setIndex update.index
    @removeAnnouncements update.deletes
    @addAnnouncements update.updates
    @computeDiscoveryServers()

  removeAnnouncements: (ids) ->
    @_announcements = _.omit(@_announcements, ids)

  addAnnouncements: (announcements) ->
    @_announcements = _.extend @_announcements,
      _.indexBy(announcements, "announcementId")

  getAnnouncements: () ->
    @_announcements

  clearAnnouncements: () ->
    @_announcements = {}

  setIndex: (@index) ->

  computeDiscoveryServers: () ->
    @discoveryServers = _.chain @_announcements
      .where
        serviceType:"discovery"
      .pluck "serviceUri"
      .value()

  getDiscoveryServers: () ->
    @discoveryServers

  serviceTypePredicate: (serviceType, announcement) ->
    serviceType in [
      announcement.serviceType
      "#{announcement.serviceType}:#{announcement.feature}"
    ]

  findAll: (predicate, discoverRegion) ->
    throw new Error('discovery region required') unless discoverRegion?
    
    unless _.isFunction predicate
      predicate = @serviceTypePredicate.bind @, predicate

    # Return services but if we have services from our home/discoverRegion return those over
    # ones in external regions
    _.chain @_announcements
      .filter predicate
      .groupBy 'serviceType'
      .map (services) ->
        bothRegions = _.partition services, (service) ->
          service.environment == discoverRegion

        if bothRegions[0].length > 0 then bothRegions[0] else bothRegions[1]
      .flatten()
      .pluck "serviceUri"
      .value()

  find: (predicate, discoverRegion) ->
    _.sample @findAll(predicate, discoverRegion)

module.exports = AnnouncementIndex
