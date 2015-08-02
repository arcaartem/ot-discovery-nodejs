var config = {
  logger: {
    log: function () { console.log.apply(console, arguments); },
    error: function () { console.error.apply(console, arguments); }
  },
  discovery: {
    shouldPublish: true,
    service: 'localhost:4440',
    serviceType: 'demo-service',
  },
  getUri: function() { return 'fake://service'; }
};

module.exports = config;
