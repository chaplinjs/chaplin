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
  if (useDeps === true) {
    paths.jquery = '../' + componentsFolder + '/jquery/jquery';
    paths.underscore = '../' + componentsFolder + '/lodash/lodash.compat';
  } else {
    paths.NativeView = '../' + componentsFolder + '/backbone.nativeview/backbone.nativeview';
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

requirejs.config(config);
if (testType === 'exos') {
  define('jquery', function(){});
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

  if (useDeps === true) {
    require(specs, run)
  } else {
    define('underscore', function(){});
    require(['backbone', 'NativeView'], function(Backbone, NativeView) {
      requirejs.undef('underscore')
      define('underscore', function(){
        var _ = Backbone.utils
        _.bind = function(fn, ctx) { return fn.bind(ctx); }
        _.isObject = function(obj) {
            var type = typeof obj;
            return type === 'function' || type === 'object' && !!obj;
          };
        _.clone = function(obj) {
          if (!_.isObject(obj)) return obj;
          return Array.isArray(obj) ? obj.slice() : _.extend({}, obj);
        };
        _.isEmpty = function(obj) {
          if (obj == null) return true;
          if (obj.length !== undefined) return obj.length === 0;
          return Object.keys(obj).length === 0;
        };
        return _
      });
      Backbone.View = NativeView;
      require(specs, run)
    });
  }
}, false);
