var request = require('request');
var uuid = require('uuid');
var util = require('util');

var generateAnnouncement = function() {
  return {
    announcementId: uuid.v4(),
    serviceType: 'chaos-lemur',
    serviceUri: 'http://www.example.com/' + uuid.v4()
  };
};

var random = function() {
  return Math.floor(Math.random() * 5000 + 100);
};

var unannounce = function(id) {
  console.log("Unannouncing: " + id);
  request({
    url: "http://localhost:4440/announcement/" + id,
    method: "DELETE"
  }, function (error, response, body) {
    if (error) {
      console.log('Error while unnanouncing: ' + error);
    }
  });
};

var announce = function() {
  var announcement = generateAnnouncement();
  console.log("Announcing: " + announcement.announcementId);
  request({
    url: "http://localhost:4440/announcement",
    method: "POST",
    json: true,
    body: announcement
  }, function (error, response, body) {
    if (error) {
      console.log("Error occured while announcing: " + util.inspect(error));
      return;
    }
    if (response.statusCode != 201) {
      console.log("During announce, bad status code " + response.statusCode + ": " + JSON.stringify(body));
      return;
    }
    setTimeout(function() { unannounce(announcement.announcementId); }, random());
  });
};

var induceChaos = function() {
  console.log("Chaos!");
  setTimeout(announce, random());
};

var interval = setInterval(induceChaos, 500);
setTimeout(function () { clearInterval(interval); }, 60 * 60 * 1000);
