
var exec = require('cordova/exec');

var PLUGIN_NAME = 'MobilityUtils';

var MobilityUtils = {
  echo: function(phrase, cb) {
    exec(cb, null, PLUGIN_NAME, 'echo', [phrase]);
  },
  getDate: function(cb) {
    exec(cb, null, PLUGIN_NAME, 'getDate', []);
  },
  loadProps: function(cb) {
    exec(cb, null, PLUGIN_NAME, 'loadProps', []);
  }
};

module.exports = MobilityUtils;