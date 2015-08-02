var Discovery = require('./discovery_wrapper');
var heapdump = require('heapdump');
var uuid = require('node-uuid');
var mkdirp = require('node-mkdirp');
var moment = require('moment');


var timestamp = function() { return moment().format().replace(/[-:+]/g, ''); };

var snapshotFilename = function(id) { return './snapshots/' + id + '/snapshot-' + id + '-' + timestamp() + '.heapsnapshot'; };

var id = uuid.v4();
mkdirp('./snapshots/' + id);
var disco = new Discovery(id);

heapdump.writeSnapshot(snapshotFilename(id));
disco.BeginPublishing();
setInterval(function() { heapdump.writeSnapshot(snapshotFilename(id)); }, 30 * 60 * 1000);
