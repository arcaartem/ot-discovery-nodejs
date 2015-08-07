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
//DiscoveryClient(host, announcementHosts, homeRegionName, serviceName, options)

var discovery = require("ot-discovery");
var disco = new discovery('discovery-server.mydomain.com', ['discovery-server.mydomain.com', 'discovery-server.otherdomain.com'],
  'homeDiscoRegion', 'myServiceName', { /* options */});

//alternatively the original v1 constructor will continue to work (but will not utilize apiv2 features, mostly multi region announce)
// THIS WILL BE DEPRECATED EVENTUALLY AND ALL CLIENTS SHOULD BE USING 2.0 CONSTRUCTOR ARGUMENTS GOING FORWARD.  
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

disco.connect(function(err, host, servers){
  disco.announce({
    "serviceType":"myServiceType",
    "serviceUri":"http://1.1.1.1:3"
  }, function(announcedItems){
    //announcedItems is an array because you could potentially be multi-region announcing (thus getting back more than one result)
    console.log("We announced our service!", announcedItems);
  }); 
});

```
