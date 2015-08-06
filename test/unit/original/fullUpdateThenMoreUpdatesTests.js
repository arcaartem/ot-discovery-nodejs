var assert = require("assert");
var nock = require('nock');
var constants = require('./testConstants.js');
var utils = require('./testUtils.js');
var fullUpdate;
var smallUpdate;
var noUpdate;
var TOTAL_TEST_TIME = 3000;
var UPDATE_TIME_DELAY_MS = 2000;
var ACCEPTABLE_UPDATE_LAG = 50;

describe('# full-update followed by some updates tests', function(){
  beforeEach(function(done){
    nock.cleanAll();
    nock.disableNetConnect();

      fullUpdate = nock(constants.DISCOVERY_URL)
            .get('/watch')
            .reply(200, {
              "fullUpdate":true,
              "index":100,
              "deletes":[],
              "updates":[
                  {
                    "announcementId":"discovery",
                    "staticAnnouncement":false,
                    "announceTime":"2015-03-30T18:26:52.178Z",
                    "serviceType":"discovery",
                    "serviceUri":constants.DISCOVERY_SERVER_URLS[0]
                  },
                  {
                    "announcementId":"old",
                    "staticAnnouncement":false,
                    "announceTime":"2015-03-30T18:26:52.178Z",
                    "serviceType":"my-service",
                    "serviceUri":"http://1.1.1.1:2"
                  }
                ]
              });

    smallUpdate = nock(constants.DISCOVERY_SERVER_URLS[0])
            .get('/watch?since=' + 101)
            .delayConnection(UPDATE_TIME_DELAY_MS)
            .reply(200, {
              "fullUpdate":false,
              "index":101,
              "deletes":['old'],
              "updates":[{
                    "announcementId":"new1",
                    "staticAnnouncement":false,
                    "announceTime":"2015-03-30T18:26:52.178Z",
                    "serviceType":"my-service-new1",
                    "serviceUri":"http://2.2.2.2:2"
                  },
                  {
                    "announcementId":"new2",
                    "staticAnnouncement":false,
                    "announceTime":"2015-03-30T18:26:52.178Z",
                    "serviceType":"my-service-new2",
                    "serviceUri":"http://3.3.3.3:3"
                  }]
              });

    noUpdate = nock(constants.DISCOVERY_SERVER_URLS[0])
            .get('/watch?since=' + 102)
            .delayConnection(10000)
            .reply(204);

    done();
   });

  afterEach(function(done) {
    if(this.disco && this.disco.dispose) {
      this.disco.dispose()
    }
    nock.cleanAll();
    nock.enableNetConnect();
    done();
  });

    it('should call watch, watch?since= and correctly populate announcements', function (done){
      this.timeout(constants.TIMEOUT_MS);
      var disco = this.disco = new discovery(constants.DISCOVERY_HOST, constants.DISCOVERY_OPTIONS);

      disco.connect(function(error, host, servers) {
        assert.equal(constants.DISCOVERY_HOST, host)
        assert.deepEqual(servers, [constants.DISCOVERY_SERVER_URLS[0]])

        fullUpdate.done();
      });

      var onUpdateReceived = false;
      var start = new Date();
      disco.onUpdate(function(arg1, arg2, arg3) {
        onUpdateReceived = true;
        assertUpdateWasReceived();
        assertUpdateWasReceivedOnTime();
        smallUpdate.done();
        assertStates();
      });

      setTimeout(function() {
        assertUpdateWasReceived();
        noUpdate.done();
        assertStates();
        done();
      }, TOTAL_TEST_TIME);

      function assertUpdateWasReceived() {
        assert.equal(true, onUpdateReceived);
      }

      function assertUpdateWasReceivedOnTime() {
        var end = new Date();
        var timeDiff = utils.timeDiffMS(end, start);
        var timeDiffAcceptable = (timeDiff < UPDATE_TIME_DELAY_MS + ACCEPTABLE_UPDATE_LAG);
        assert.equal(true, timeDiffAcceptable);
      }

      function assertStates() {
        var announcements = disco.getAnnouncements();
        assert.equal(3, Object.keys(announcements).length);
        assert.equal(true, announcements.hasOwnProperty('discovery'));
        assert.equal(true, announcements.hasOwnProperty('new1'));
        assert.equal(true, announcements.hasOwnProperty('new2'));
        assert.equal('discovery', announcements['discovery'].serviceType);
        assert.equal('my-service-new1', announcements['new1'].serviceType);
        assert.equal('my-service-new2', announcements['new2'].serviceType);
      }
    });
 });
