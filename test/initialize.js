// Fix timers stubbing in IE8-9.
var oldTimers = {setInterval: setInterval, clearInterval: clearInterval};
eval('function setInterval() {}; function clearInterval() {}');
var oldIE = (/MSIE [89]/.test(navigator.userAgent));
var timers = oldIE ? sinon.clock : oldTimers;
window.setInterval = timers.setInterval;
window.clearInterval = timers.clearInterval;

var paths = {};

var match = window.location.search.match(/type=([-\w]+)/)
var testType = window.testType || (match ? match[1] : 'backbone');

var addDeps = function() {
  paths.underscore = '../bower_components/lodash/dist/lodash.compat';
  paths.jquery = '../bower_components/jquery/jquery';
};
if (testType === 'backbone') {
  paths.backbone = '../bower_components/backbone/backbone'
  addDeps()
} else {
  if (testType === 'deps') addDeps();
  paths.backbone = '../bower_components/exoskeleton/exoskeleton'
}

var config = {
  baseUrl: 'temp/',
  paths: paths,
  // For easier development, disable browser caching
  urlArgs: 'bust=' + (new Date()).getTime()
};

if (testType === 'backbone' || testType === 'deps') {
  config.shim = {
    backbone: {
      deps: ['underscore', 'jquery'],
      exports: 'Backbone'
    },
    underscore: {
      exports: '_'
    }
  };
}

requirejs.config(config);
if (testType === 'exos') {
  define('jquery', function(){});
  define('underscore', ['backbone'], function(Backbone){return Backbone.utils;});
}
mocha.setup({ui: 'bdd', ignoreLeaks: true});
// Wonderful hack to send a message to grunt from inside a mocha test.
var sendMessage = function() {
  var args = [].slice.call(arguments);
  // Remove if when generating test coverage.
  if (window.mochaPhantomJS) {
     alert(JSON.stringify(args));
  }
};
mocha.suite.afterAll(function() {
  sendMessage('mocha.coverage', window.__coverage__);
});
window.expect = SinonExpect.enhance(expect, sinon, 'was');
window.addEventListener('DOMContentLoaded', function() {
  var specs = [
    'event_broker',
    'mediator',
    'router',
    'application',
    'layout',
    'dispatcher',
    'composer',
    'composition',
    'collection_view',
    'model',
    'collection',
    'controller',
    'view',
    'delayer',
    'utils',
    'helpers',
    'sync_machine'
  ];
  var loaded = [];
  for (var i = 0, l = specs.length; i < l; i++) {
    loaded.push(specs[i] + '_spec');
  }
  require(loaded, function() {
    if (window.mochaPhantomJS) {
      mochaPhantomJS.run();
    } else {
      mocha.run();
    }
  });
}, false);
