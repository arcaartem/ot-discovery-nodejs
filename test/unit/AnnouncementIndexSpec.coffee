AnnouncementIndex = require "#{srcDir}/AnnouncementIndex"
sinon = require "sinon"

describe "AnnouncementIndex", ->
  beforeEach ->
    @announcementIndex = new AnnouncementIndex

    @sampleAnnouncements = [
      {
        "announcementId":"a1"
        "environment":"prod-uswest2"
        "feature":"test"
        "serviceType":"discovery"
        "serviceUri":"http://1.1.1.1:2"
      },
      {
        "announcementId":"a2"
        "environment":"prod-sc"
        "serviceType":"myservice"
        "serviceUri":"http://2.2.2.2:2"
      }
    ]

    @announcementIndex.addAnnouncements @sampleAnnouncements

  it "addAnnouncements", ->
    expect(@announcementIndex.getAnnouncements()["a1"])
      .to.deep.equal @sampleAnnouncements[0]

    expect(@announcementIndex.getAnnouncements()["a2"])
      .to.deep.equal @sampleAnnouncements[1]

    @announcementIndex.addAnnouncements [{
      "announcementId":"a1"
      "serviceType":"discovery"
    }]

    expect(@announcementIndex.getAnnouncements()["a1"]).to.deep.equal {
      "announcementId":"a1"
      "serviceType":"discovery"
    }

  it "removeAnnouncements", ->
    @announcementIndex.removeAnnouncements(["a2"])
    expect(@announcementIndex.getAnnouncements()).to.deep.equal {
      "a1":@sampleAnnouncements[0]
    }

  it "clearAnnouncements()", ->
    @announcementIndex.clearAnnouncements()
    expect(@announcementIndex.getAnnouncements()).to.deep.equal {}

  it "computeDiscoverServers()", ->
    @announcementIndex.computeDiscoveryServers()
    expect(@announcementIndex.getDiscoveryServers())
      .to.deep.equal [@sampleAnnouncements[0].serviceUri]

  it "processUpdate - fullUpdate", ->
    @announcementIndex.processUpdate
      fullUpdate:true
      index:1
      deletes:[]
      updates:[
        {announcementId:"b1", serviceType:"gc-web", serviceUri:"gcweb.otenv.com"}
        {announcementId:"b2", serviceType:"discovery", serviceUri:"discovery.otenv.com"}
      ]

    expect(@announcementIndex.getAnnouncements()).to.deep.equal {
      b1:
        announcementId: 'b1',
        serviceType: 'gc-web',
        serviceUri: 'gcweb.otenv.com'
      b2:
        announcementId: 'b2',
        serviceType: 'discovery',
        serviceUri: 'discovery.otenv.com'
    }
    expect(@announcementIndex.index).to.equal 1
    expect(@announcementIndex.discoveryServers).to.deep.equal [
      "discovery.otenv.com"
    ]

  it "fullUpdate with removal of old items on new watch=x update, and fullUpdate:false", ->
    @announcementIndex.processUpdate
      fullUpdate:true
      index:1
      deletes:[]
      updates:[
        {announcementId:"b1", serviceType:"gc-web", serviceUri:"gcweb.otenv.com"}
        {announcementId:"b2", serviceType:"discovery", serviceUri:"discovery.otenv.com"}
      ]

    @announcementIndex.processUpdate
      fullUpdate:false
      index:2
      deletes:["b1"]
      updates:[]

    expect(@announcementIndex.getAnnouncements()).to.deep.equal {
      b2:
        announcementId: 'b2',
        serviceType: 'discovery',
        serviceUri: 'discovery.otenv.com'
    }
    expect(@announcementIndex.index).to.equal 2
    expect(@announcementIndex.discoveryServers).to.deep.equal [
      "discovery.otenv.com"
    ]

  describe "findAll()", ->
    it 'throws if no discovery region is passed in', ->
      try
        @announcementIndex.findAll 'region'
      catch e
        return expect(e).to.be.ok
      assert.fail 'exception did not get thrown'

    describe 'with discoveryRegion defined to a non-announcing region  (fallback to other regions)', ->
      {sampleAnnouncements} = {}

      beforeEach ->
        sampleAnnouncements = [
          {
            "announcementId":"b1"
            "environment":"prod-uswest2"
            "feature":"test"
            "serviceType":"discovery"
            "serviceUri":"http://1.1.1.1:prod-uswest2"
          },
          {
            "announcementId":"b2"
            "environment":"prod-sc"
            "serviceType":"myservice"
            "serviceUri":"http://2.2.2.2:prod-sc"
          }
        ]

        @announcementIndex.addAnnouncements sampleAnnouncements

      it 'retrieves all announcements for that service', ->
        results = @announcementIndex.findAll 'discovery', 'prod-sc'
        expect(results).to.have.length 2
        expect(results).to.deep.equal [
          @sampleAnnouncements[0].serviceUri
          sampleAnnouncements[0].serviceUri
        ]

      it 'will not retrieve disco announcements for services with an undefined feature', ->
        expect(@announcementIndex.findAll('discovery:none', 'prod-sc')).to.deep.equal []

      it 'will retrieve disco announcements for services with a defined feature', ->
        expect(@announcementIndex.findAll('discovery:test', 'prod-sc')).to.deep.equal [
          @sampleAnnouncements[0].serviceUri
          sampleAnnouncements[0].serviceUri
        ]

    describe 'with discoveryRegion defined and mixed region discovery announcements', ->
      {sampleAnnouncements} = {}

      beforeEach ->
        sampleAnnouncements = [
          {
            "announcementId":"b1"
            "environment":"prod-sc"
            "feature":"test"
            "serviceType":"discovery"
            "serviceUri":"http://1.1.1.1:prod-sc"
          },
          {
            "announcementId":"b2"
            "environment":"prod-uswest2"
            "serviceType":"myservice"
            "serviceUri":"http://2.2.2.2:prod-uswest2"
          }
        ]

        @announcementIndex.addAnnouncements sampleAnnouncements

      it 'retrieves all announcements for that service for the given region', ->
        results = @announcementIndex.findAll 'discovery', 'prod-sc'
        expect(results).to.have.length 1
        expect(results).to.deep.equal [ sampleAnnouncements[0].serviceUri ]

      it 'retrieves all announcements for that service for the other region', ->
        results = @announcementIndex.findAll 'discovery', 'prod-uswest2'
        expect(results).to.have.length 1
        expect(results).to.deep.equal [ @sampleAnnouncements[0].serviceUri ]

      it 'retrieves all announcements for that service with a unannounced region', ->
        results = @announcementIndex.findAll 'discovery', 'foo-bar-land'
        expect(results).to.have.length 2
        expect(results).to.deep.equal [
          @sampleAnnouncements[0].serviceUri
          sampleAnnouncements[0].serviceUri
        ]

      it 'will not retrieve disco announcements for services with an undefined feature', ->
        expect(@announcementIndex.findAll('discovery:none', 'prod-sc')).to.deep.equal []

      it 'will retrieve disco announcements for services with a defined feature', ->
        expect(@announcementIndex.findAll('discovery:test', 'prod-uswest2')).to.deep.equal [
          @sampleAnnouncements[0].serviceUri
        ]

      it 'will filter results by a given predicate', ->
        predicate = (announcement)->
          announcement.serviceType is 'myservice'
        expect(@announcementIndex.findAll(predicate, 'prod-uswest2')).to.deep.equal [
          sampleAnnouncements[1].serviceUri
        ]

  describe "find()", ->
    before ->
      # the beforeEach above is blowing out @announcementIndex
      @index = new AnnouncementIndex
      sinon.spy @index, 'findAll'

      # note this also tests that we find with no environment (old non-cross announcing services)
      @index.addAnnouncements [
        { "announcementId":"d1", "serviceType":"serviceA", serviceUri:"http://1.1.1.1:3"}
        { "announcementId":"d2", "serviceType":"serviceA", serviceUri:"http://1.1.1.1:4"}
        { "announcementId":"d3", "serviceType":"serviceA", serviceUri:"http://1.1.1.1:5"}
      ]

      @result = @index.find 'serviceA', 'r'

    it 'calls findAll()', ->
      expect(@index.findAll).to.have.been.called

    it 'picks one result', ->
      expect(@result).to.contain 'http://1.1.1.1'
