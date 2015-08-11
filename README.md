# OT Discovery Client
[![Build Status](https://travis-ci.org/opentable/ot-discovery-nodejs.png?branch=master)](https://travis-ci.org/opentable/ot-discovery-nodejs) [![NPM version](https://badge.fury.io/js/ot-discovery.png)](http://badge.fury.io/js/ot-discovery) ![Dependencies](https://david-dm.org/opentable/ot-discovery-nodejs.png)

Client for OT flavoured service discovery. (Note we are in the process of open-sourcing the entire Opentable discovery stack)

installation:

```
npm install ot-discovery
```

usage:


``` javascript
//constructor 
/* DiscoveryClient(host, announcementHosts, homeRegionName, serviceName, options) 
 * @param = {String} host The hostname to the discovery server.
 * @param {Array} [annoucementHosts] An array of announcement host names (multiple for announcing in multiple disco regions).
 *   If not provided will use host.  Please include hostname in the announcement hosts.
 *
 * @param {string} [homeRegionName] The name of the region you will be hosted in.
 * @param {String} [serviceName] The name of the service you will announce as.
 * @param {Object} [options] Options argument that takes the following:
 *      {
 *        logger: { log: function(level, message){}},
 *        apiv2Strict: true/[false]
 *      }
 * @returns {Object} Returns a discovery client object.
 */

var discovery = require("ot-discovery");
var disco = new discovery('discovery-server.mydomain.com', ['discovery-server.mydomain.com', 'discovery-server.otherdomain.com'],
  'homeDiscoRegion', 'myServiceName', { /* options */});

//alternatively the original v1 constructor will continue to work (but will not utilize apiv2 features, mostly multi region announce)
// This may be eventually deprecated so please consider using the v2 constructor arguments instead.
var disco = new discovery("discovery-server.mydomain.com");

```

options:

``` javascript
{
  logger: { // a logger object which implements the following signature
    log: function(severity, log){} // severity will be one of info, debug, error
  },
  apiv2Strict: false //setting to true will throw exceptions on using old apiv1 constructor params
}
```

Using with ot-logger

``` javascript
new discovery('discovery-server.mydomain.com', ['discovery-server.mydomain.com', 'discovery-server.otherdomain.com'],
  'homeDiscoRegion', 'myServiceName', { logger: require("ot-logger") });
```

General API usage

``` javascript 
var discovery = require("./discovery");
var disco = new discovery('discovery-server.mydomain.com', ['discovery-server.mydomain.com', 'discovery-server.otherdomain.com'],
  'homeDiscoRegion', 'myServiceName', { /* options */});
var that = this;

disco.connect(function(err, host, servers){
  //Please note that your http server must be up and responding to requests before announcing to a discovery server or you will get a rejected announcement!
  disco.announce({
    "serviceType":"myServiceType",
    "serviceUri":"http://1.1.1.1:3"
  }, function(err, announcedItemLeases){
    //announcedItems is an array because you could potentially be multi-region announcing (thus getting back more than one result)
    console.log("We announced our service!", announcedItems);
    //You should store these items (and do NOT modify them) somewhere if you plan to unannounce the announcements.
    that._announcedItemLeases = announcedItemLeases
  }); 
});

```

API Documentation

``` javascript
  DiscoveryClient.prototype.announce = function(announcement, callback) {}
/* 
 * @param = {Object} announcement - announcement object:
 *   {
 *      serviceType:'myServiceTypeName',
 *      serviceUri:'http://myuri.com'
 *   }
 * @param {function(err, announcedItemLeases )} callback Node style callback for success/error
 *   Please note that annoucedItemLeases is required to hold onto (UNMODIFIED) if you plan to use unannounce.
 *
 * @returns {Promise} Returns a promise object that resolves around the announcements


  DiscoveryClient.prototype.unannounce = function(announcements, callback) {}
/*
 * @param = {Array} announcements - announcement array directly from DiscoveryClient.announce - MUST NOT BE MODIFIED (INCLUDING ORDER!)
 * @param {function(err, announcedItemLeases )} callback Node style callback for success/error
 *
 * @returns {Promise} Returns a promise object that resolves around the unannounce

```
