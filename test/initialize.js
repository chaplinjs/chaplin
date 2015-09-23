// Fix timers stubbing in IE8-9.
var oldTimers = {setInterval: setInterval, clearInterval: clearInterval};
eval('function setInterval() {}; function clearInterval() {}');
var oldIE = (/MSIE [89]/.test(navigator.userAgent));
var timers = oldIE ? sinon.clock : oldTimers;
window.setInterval = timers.setInterval;
window.clearInterval = timers.clearInterval;

var paths = {};
var componentsFolder = 'bower_components';

var match = window.location.search.match(/type=([-\w]+)&useDeps=([-\w]+)/);
var testType = window.testType || (match ? match[1] : 'backbone');
var useDeps = window.useDeps || (match ? match[2] : true);

var addDeps = function() {
  if (useDeps) {
    paths.underscore = '../' + componentsFolder + '/lodash/lodash.compat';
    paths.jquery = '../' + componentsFolder + '/jquery/jquery';
  } else {
    paths.NativeView = '../' + componentsFolder + '/Backbone.NativeView/backbone.nativeview';
  }
};
if (testType === 'backbone') {
  paths.backbone = '../' + componentsFolder + '/backbone/backbone';
  addDeps();
} else {
  addDeps();
  paths.backbone = '../' + componentsFolder + '/exoskeleton/exoskeleton';
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
  define('underscore', ['backbone'], function(Backbone){
    var _ = Backbone.utils;
    _.bind = function(fn, ctx) { return fn.bind(ctx); }
    return _;
  });
}
mocha.setup({ui: 'bdd', ignoreLeaks: true});
// Wonderful hack to send a message to grunt from inside a mocha test.
var sendMessage = function() {
  var args = [].slice.call(arguments);
  // Remove if when generating test coverage.
  if (window.mochaPhantomJS)
     alert(JSON.stringify(args));
};
mocha.suite.afterAll(function() {
  sendMessage('mocha.coverage', window.__coverage__);
});
window.clickOnElement = function(el) {
  if (el.click) {
    el.click();
  } else {
    var ev = document.createEvent('Events');
    ev.initEvent('click', true, false);
    el.dispatchEvent(ev);
  }
};
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
    'utils',
    'sync_machine'
  ].map(function(file) {
    return file + '_spec';
  });

  var run = function() {
    if (window.mochaPhantomJS) {
      mochaPhantomJS.run();
    } else {
      mocha.run();
    }
  };

  require(specs, function() {
    if (useDeps) {
      run();
    } else {
      require(['backbone', 'NativeView'], function(Backbone, NativeView) {
        Backbone.View = NativeView;
        run();
      });
    }
  });
}, false);
