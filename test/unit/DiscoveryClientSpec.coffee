DiscoveryClient = require("#{srcDir}/DiscoveryClient")
ConsoleLogger = require("#{srcDir}/ConsoleLogger")
Promise = require "bluebird"
_ = require "lodash"

describe "DiscoveryClient", ->

  describe "v1 api facading", ->
    it "supports just a host and options", ->
      options = {}
      client = new DiscoveryClient 'anything', options
      expect(client.host).to.equal('anything')
      expect(client._announcementHosts).to.deep.equal(['anything'])
      expect(client.homeRegionName).to.not.be.ok
      expect(client.serviceName).to.not.be.ok
      expect(client.options).to.equal(options)

  it "uses logger if not passed", ->
    client = new DiscoveryClient 'anything'
    expect(client.logger).to.equal(require("#{srcDir}/ConsoleLogger"))

  it "uses options logger if passed", ->
    myLogger =
      log: () ->

    client = new DiscoveryClient 'anything', {logger: myLogger}
    expect(client.logger).to.equal(myLogger)

  describe "v2 api", ->
    beforeEach ->
      @discoveryClient = Promise.promisifyAll new DiscoveryClient(
        api2testHosts.discoverRegionHost,
        api2testHosts.announceHosts,
        'homeregion',
        testServiceName, {
          logger:
            log: () ->
        })

      @announcers = @discoveryClient._discoveryAnnouncers

    it "creates announcers in each region", ->
      expect(@announcers).to.have.length(2)

    it "connect connects, long polls, and heartbeats", (done) ->
      updates =
        fullUpdate: true
        index: 1
        updates: [{
          serviceType: 'discovery',
          serviceUri: 'a.disco'
        }]

      @discoveryClient.discoveryConnector.connect = sinon.spy () ->
        return Promise.resolve(updates)

      sinon.spy(@discoveryClient.announcementIndex, 'processUpdate')
      @discoveryClient.longPollForUpdates = sinon.spy()
      @discoveryClient.startAnnouncementHeartbeat = sinon.spy()
      @discoveryClient.connect (err, host, servers) =>
        if err
          return done(err)

        expect(@discoveryClient.announcementIndex.processUpdate.calledWith(updates))
          .to.be.ok
        expect(@discoveryClient.longPollForUpdates.called)
          .to.be.ok
        expect(@discoveryClient.startAnnouncementHeartbeat.called)
          .to.be.ok
        expect(host).to.equal(api2testHosts.discoverRegionHost)
        expect(servers).to.deep.equal(['a.disco'])

        done()

    it "heartbeat start calls heartbeat on each region", ->
      _.each @announcers, (ann) ->
        ann.startAnnouncementHeartbeat = sinon.spy()
      @discoveryClient.startAnnouncementHeartbeat()
      _.each @announcers, (ann) ->
        expect(ann.startAnnouncementHeartbeat.called).to.be.ok

    it "heartbeat stop calls heartbeat on each region", ->
      _.each @announcers, (ann) ->
        ann.stopAnnouncementHeartbeat = sinon.spy()
      @discoveryClient.stopAnnouncementHeartbeat()
      _.each @announcers, (ann) ->
        expect(ann.stopAnnouncementHeartbeat.called).to.be.ok

    it "announce announces in each region", (done) ->
      _.each @announcers, (ann) ->
        ann.announce = sinon.spy (announce) ->
          Promise.resolve(announce)
      announcement = {}
      @discoveryClient.announce(announcement).then (result) =>
        expect(result).to.deep.equal([announcement, announcement])
        expect(@announcers[0].announce.calledWith(announcement)).to.be.ok
        expect(@announcers[1].announce.calledWith(announcement)).to.be.ok
        expect(@announcers[0].announce.calledOn(@announcers[0])).to.be.ok
        expect(@announcers[1].announce.calledOn(@announcers[1])).to.be.ok
        done()
      .catch(done)

    it "announce fails if one announce fails", (done) ->
      @announcers[0].announce = sinon.spy (announce) ->
        Promise.resolve(announce)
      @announcers[1].announce = sinon.spy (announce) ->
        Promise.reject new Error('an error')

      @discoveryClient.announce({}).then (result) ->
        done new Error('should not get here')
      .catch (err) ->
        expect(err).to.be.ok
        done()

    it "unannounce unannounces in each region", (done) ->
      _.each @announcers, (ann) ->
        ann.unannounce = sinon.spy (a) ->
          Promise.resolve()

      @discoveryClient.unannounce([1,2]).then () =>
        expect(@announcers[0].unannounce.calledWith(1)).to.be.ok
        expect(@announcers[1].unannounce.calledWith(2)).to.be.ok
        expect(@announcers[0].unannounce.calledOn(@announcers[0])).to.be.ok
        expect(@announcers[1].unannounce.calledOn(@announcers[1])).to.be.ok
        done()
      .catch(done)

    it "unannounce fails if one unannounce fails", (done) ->
      @announcers[0].unannounce = sinon.spy()
      @announcers[1].unannounce = sinon.spy () ->
        Promise.reject new Error('something')

      @discoveryClient.unannounce([1,2]).then () ->
        done new Error('should not get here')
      .catch (err) =>
        expect(err).to.be.ok
        done()

    it "dispose stops everything", ->
      @discoveryClient.stopAnnouncementHeartbeat = sinon.spy()
      @discoveryClient.discoveryLongPoller.stopPolling = sinon.spy()
      @discoveryClient.dispose()
      expect(@discoveryClient.stopAnnouncementHeartbeat.called).to.be.ok
      expect(@discoveryClient.discoveryLongPoller.stopPolling.called).to.be.ok

    it "find calls announcementIndex", ->
      @discoveryClient.announcementIndex.find = sinon.spy()
      @discoveryClient.find("discovery")
      expect(@discoveryClient.announcementIndex.find.called).to.be.ok

    it "findAll calls announcementIndex", ->
      @discoveryClient.announcementIndex.findAll = sinon.spy()
      @discoveryClient.findAll("discovery")
      expect(@discoveryClient.announcementIndex.findAll.called).to.be.ok

    it "reconnect just connects", ->
      @discoveryClient.connect = sinon.spy()
      @discoveryClient.reconnect()
      expect(@discoveryClient.connect.called).to.be.ok

    it "make sure discovery can be promisified", ->
      expect(@discoveryClient.connectAsync).to.exist
      expect(@discoveryClient.announceAsync).to.exist
      expect(@discoveryClient.unannounceAsync).to.exist
