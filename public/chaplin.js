(function(/*! Brunch !*/) {
  'use strict';

  if (!this.require) {
    var modules = {};
    var cache = {};
    var __hasProp = ({}).hasOwnProperty;

    var expand = function(root, name) {
      var results = [], parts, part;
      if (/^\.\.?(\/|$)/.test(name)) {
        parts = [root, name].join('/').split('/');
      } else {
        parts = name.split('/');
      }
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part == '..') {
          results.pop();
        } else if (part != '.' && part != '') {
          results.push(part);
        }
      }
      return results.join('/');
    };

    var getFullPath = function(path, fromCache) {
      var store = fromCache ? cache : modules;
      var dirIndex;
      if (__hasProp.call(store, path)) return path;
      dirIndex = expand(path, './index');
      if (__hasProp.call(store, dirIndex)) return dirIndex;
    };
    
    var cacheModule = function(name, path, contentFn) {
      var module = {id: path, exports: {}};
      try {
        cache[path] = module.exports;
        contentFn(module.exports, function(name) {
          return require(name, dirname(path));
        }, module);
        cache[path] = module.exports;
      } catch (err) {
        delete cache[path];
        throw err;
      }
      return cache[path];
    };

    var require = function(name, root) {
      var path = expand(root, name);
      var fullPath;

      if (fullPath = getFullPath(path, true)) {
        return cache[fullPath];
      } else if (fullPath = getFullPath(path, false)) {
        return cacheModule(name, fullPath, modules[fullPath]);
      } else {
        throw new Error("Cannot find module '" + name + "'");
      }
    };

    var dirname = function(path) {
      return path.split('/').slice(0, -1).join('/');
    };

    this.require = function(name) {
      return require(name, '');
    };

    this.require.brunch = true;
    this.require.define = function(bundle) {
      for (var key in bundle) {
        if (__hasProp.call(bundle, key)) {
          modules[key] = bundle[key];
        }
      }
    };
  }
}).call(this);
(this.require.define({
  "/Users/paul/Development/chaplin/config": function(exports, require, module) {
    (function() {

  exports.config = {
    paths: {
      public: 'public'
    },
    files: {
      javascripts: {
        joinTo: 'chaplin.js'
      }
    }
  };

}).call(this);

  }
}));
(this.require.define({
  "chaplin/application": function(exports, require, module) {
    (function() {
  var Application, ApplicationController, ApplicationView, Router, mediator;

  mediator = require('mediator');

  ApplicationController = require('chaplin/controllers/application_controller');

  ApplicationView = require('chaplin/views/application_view');

  Router = require('chaplin/lib/router');

  require('lib/view_helper');

  module.exports = Application = (function() {

    function Application() {}

    Application.prototype.title = '';

    Application.prototype.applicationController = null;

    Application.prototype.applicationView = null;

    Application.prototype.router = null;

    Application.prototype.initialize = function() {
      this.applicationController = new ApplicationController();
      return this.applicationView = new ApplicationView({
        title: this.title
      });
    };

    Application.prototype.initRouter = function(routes) {
      this.router = new Router();
      if (typeof routes === "function") routes(this.router.match);
      return this.router.startHistory();
    };

    Application.prototype.disposed = false;

    Application.prototype.dispose = function() {
      var prop, properties, _i, _len;
      if (this.disposed) return;
      properties = ['applicationController', 'applicationView', 'router'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        this[prop].dispose();
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Application;

  })();

}).call(this);

  }
}));
(this.require.define({
  "chaplin/controllers/application_controller": function(exports, require, module) {
    (function() {
  var ApplicationController, Subscriber, mediator, utils;

  mediator = require('mediator');

  utils = require('chaplin/lib/utils');

  Subscriber = require('chaplin/lib/subscriber');

  module.exports = ApplicationController = (function() {

    _(ApplicationController.prototype).extend(Subscriber);

    ApplicationController.prototype.previousControllerName = null;

    ApplicationController.prototype.currentControllerName = null;

    ApplicationController.prototype.currentController = null;

    ApplicationController.prototype.currentAction = null;

    ApplicationController.prototype.currentParams = null;

    ApplicationController.prototype.url = null;

    function ApplicationController() {
      this.initialize();
    }

    ApplicationController.prototype.initialize = function() {
      this.subscribeEvent('matchRoute', this.matchRoute);
      return this.subscribeEvent('!startupController', this.startupController);
    };

    ApplicationController.prototype.matchRoute = function(route, params) {
      return this.startupController(route.controller, route.action, params);
    };

    ApplicationController.prototype.startupController = function(controllerName, action, params) {
      var controller, controllerFileName, isSameController;
      if (action == null) action = 'index';
      if (params == null) params = {};
      if (params.changeURL !== false) params.changeURL = true;
      if (params.forceStartup !== true) params.forceStartup = false;
      isSameController = !params.forceStartup && this.currentControllerName === controllerName && this.currentAction === action && (!this.currentParams || _(params).isEqual(this.currentParams));
      if (isSameController) return;
      controllerFileName = utils.underscorize(controllerName) + '_controller';
      controller = require("controllers/" + controllerFileName);
      return this.controllerLoaded(controllerName, action, params, controller);
    };

    ApplicationController.prototype.controllerLoaded = function(controllerName, action, params, ControllerConstructor) {
      var controller, currentController, currentControllerName;
      currentControllerName = this.currentControllerName || null;
      currentController = this.currentController || null;
      if (currentController) {
        mediator.publish('beforeControllerDispose', currentController);
        currentController.dispose(params, controllerName);
      }
      controller = new ControllerConstructor();
      controller.initialize(params, currentControllerName);
      controller[action](params, currentControllerName);
      this.previousControllerName = currentControllerName;
      this.currentControllerName = controllerName;
      this.currentController = controller;
      this.currentAction = action;
      this.currentParams = params;
      this.adjustURL(controller, params);
      return mediator.publish('startupController', {
        previousControllerName: this.previousControllerName,
        controller: this.currentController,
        controllerName: this.currentControllerName,
        params: this.currentParams
      });
    };

    ApplicationController.prototype.adjustURL = function(controller, params) {
      var url;
      if (params.path) {
        url = params.path;
      } else if (typeof controller.historyURL === 'function') {
        url = controller.historyURL(params);
      } else if (typeof controller.historyURL === 'string') {
        url = controller.historyURL;
      } else {
        throw new Error('ApplicationController#adjustURL: controller for ' + ("" + this.currentControllerName + " does not provide a historyURL"));
      }
      if (params.changeURL) mediator.publish('!router:changeURL', url);
      return this.url = url;
    };

    ApplicationController.prototype.disposed = false;

    ApplicationController.prototype.dispose = function() {
      if (this.disposed) return;
      this.unsubscribeAllEvents();
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return ApplicationController;

  })();

}).call(this);

  }
}));
(this.require.define({
  "chaplin/controllers/controller": function(exports, require, module) {
    (function() {
  var Controller, Subscriber,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty;

  Subscriber = require('chaplin/lib/subscriber');

  module.exports = Controller = (function() {

    _(Controller.prototype).extend(Subscriber);

    Controller.prototype.view = null;

    Controller.prototype.currentId = null;

    function Controller() {
      this.dispose = __bind(this.dispose, this);      this.initialize();
    }

    Controller.prototype.initialize = function() {};

    Controller.prototype.disposed = false;

    Controller.prototype.dispose = function() {
      var obj, prop, properties, _i, _len;
      if (this.disposed) return;
      for (prop in this) {
        if (!__hasProp.call(this, prop)) continue;
        obj = this[prop];
        if (obj && typeof obj.dispose === 'function') {
          obj.dispose();
          delete this[prop];
        }
      }
      this.unsubscribeAllEvents();
      properties = ['currentId'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Controller;

  })();

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/create_mediator": function(exports, require, module) {
    (function() {
  var descriptorsSupported, support;

  support = require('chaplin/lib/support');

  descriptorsSupported = support.propertyDescriptors;

  module.exports = function(options) {
    var defineProperty, mediator, privateUser, readonly, readonlyDescriptor;
    if (options == null) options = {};
    _(options).defaults({
      createRouterProperty: true,
      createUserProperty: true
    });
    defineProperty = function(prop, descriptor) {
      if (!descriptorsSupported) return;
      return Object.defineProperty(mediator, prop, descriptor);
    };
    readonlyDescriptor = {
      writable: false,
      enumerable: true,
      configurable: false
    };
    readonly = function() {
      var prop, _i, _len, _results;
      if (!descriptorsSupported) return;
      _results = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        prop = arguments[_i];
        _results.push(defineProperty(prop, readonlyDescriptor));
      }
      return _results;
    };
    mediator = {};
    mediator.subscribe = mediator.on = Backbone.Events.on;
    mediator.unsubscribe = mediator.off = Backbone.Events.off;
    mediator.publish = mediator.trigger = Backbone.Events.trigger;
    mediator._callbacks = null;
    readonly('subscribe', 'unsubscribe', 'publish');
    if (options.createUserProperty) {
      mediator.user = null;
      privateUser = null;
      defineProperty('user', {
        get: function() {
          return privateUser;
        },
        set: function() {
          throw new Error('mediator.user is not writable directly. ' + 'Please use mediator.setUser instead.');
        },
        enumerable: true,
        configurable: false
      });
      mediator.setUser = function(user) {
        if (descriptorsSupported) {
          return privateUser = user;
        } else {
          return mediator.user = user;
        }
      };
      readonly('setUser');
    }
    return mediator;
  };

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/route": function(exports, require, module) {
    (function() {
  var Route, mediator,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty;

  mediator = require('mediator');

  module.exports = Route = (function() {
    var escapeRegExp, queryStringFieldSeparator, queryStringValueSeparator, reservedParams;

    reservedParams = 'path changeURL'.split(' ');

    escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;

    queryStringFieldSeparator = '&';

    queryStringValueSeparator = '=';

    function Route(pattern, target, options) {
      var _ref;
      this.options = options != null ? options : {};
      this.handler = __bind(this.handler, this);
      this.addParamName = __bind(this.addParamName, this);
      this.pattern = pattern;
      _ref = target.split('#'), this.controller = _ref[0], this.action = _ref[1];
      this.createRegExp();
    }

    Route.prototype.createRegExp = function() {
      var pattern;
      if (_.isRegExp(this.pattern)) {
        this.regExp = this.pattern;
        return;
      }
      pattern = this.pattern.replace(escapeRegExp, '\\$&').replace(/:(\w+)/g, this.addParamName);
      return this.regExp = RegExp("^" + pattern + "(?=\\?|$)");
    };

    Route.prototype.addParamName = function(match, paramName) {
      if (this.paramNames == null) this.paramNames = [];
      if (_(reservedParams).include(paramName)) {
        throw new Error("Route#addParamName: parameter name " + paramName + " is reserved");
      }
      this.paramNames.push(paramName);
      return '([\\w-]+)';
    };

    Route.prototype.test = function(path) {
      var constraint, constraints, matched, name, params;
      matched = this.regExp.test(path);
      if (!matched) return false;
      constraints = this.options.constraints;
      if (constraints) {
        params = this.extractParams(path);
        for (name in constraints) {
          if (!__hasProp.call(constraints, name)) continue;
          constraint = constraints[name];
          if (!constraint.test(params[name])) return false;
        }
      }
      return true;
    };

    Route.prototype.handler = function(path, options) {
      var params;
      params = this.buildParams(path, options);
      return mediator.publish('matchRoute', this, params);
    };

    Route.prototype.buildParams = function(path, options) {
      var params, patternParams, queryParams;
      params = {};
      queryParams = this.extractQueryParams(path);
      _(params).extend(queryParams);
      patternParams = this.extractParams(path);
      _(params).extend(patternParams);
      _(params).extend(this.options.params);
      params.changeURL = Boolean(options && options.changeURL);
      params.path = path;
      return params;
    };

    Route.prototype.extractParams = function(path) {
      var index, match, matches, paramName, params, _len, _ref;
      params = {};
      matches = this.regExp.exec(path);
      _ref = matches.slice(1);
      for (index = 0, _len = _ref.length; index < _len; index++) {
        match = _ref[index];
        paramName = this.paramNames ? this.paramNames[index] : index;
        params[paramName] = match;
      }
      return params;
    };

    Route.prototype.extractQueryParams = function(path) {
      var current, field, matches, pair, pairs, params, queryString, regExp, value, _i, _len, _ref;
      params = {};
      regExp = /\?(.+?)(?=#|$)/;
      matches = regExp.exec(path);
      if (!matches) return params;
      queryString = matches[1];
      pairs = queryString.split(queryStringFieldSeparator);
      for (_i = 0, _len = pairs.length; _i < _len; _i++) {
        pair = pairs[_i];
        if (!pair.length) continue;
        _ref = pair.split(queryStringValueSeparator), field = _ref[0], value = _ref[1];
        if (!field.length) continue;
        field = decodeURIComponent(field);
        value = decodeURIComponent(value);
        current = params[field];
        if (current) {
          if (current.push) {
            current.push(value);
          } else {
            params[field] = [current, value];
          }
        } else {
          params[field] = value;
        }
      }
      return params;
    };

    return Route;

  })();

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/router": function(exports, require, module) {
    (function() {
  var Route, Router, Subscriber, mediator,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  mediator = require('mediator');

  Subscriber = require('chaplin/lib/subscriber');

  Route = require('chaplin/lib/route');

  module.exports = Router = (function() {

    _(Router.prototype).extend(Subscriber);

    function Router() {
      this.route = __bind(this.route, this);
      this.match = __bind(this.match, this);      this.subscribeEvent('!router:route', this.routeHandler);
      this.subscribeEvent('!router:changeURL', this.changeURLHandler);
      this.createHistory();
    }

    Router.prototype.createHistory = function() {
      return Backbone.history || (Backbone.history = new Backbone.History());
    };

    Router.prototype.startHistory = function() {
      return Backbone.history.start({
        pushState: true
      });
    };

    Router.prototype.stopHistory = function() {
      return Backbone.history.stop();
    };

    Router.prototype.match = function(pattern, target, options) {
      var route;
      if (options == null) options = {};
      route = new Route(pattern, target, options);
      return Backbone.history.route(route, route.handler);
    };

    Router.prototype.route = function(path) {
      var handler, _i, _len, _ref;
      path = path.replace(/^(\/#|\/)/, '');
      _ref = Backbone.history.handlers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        handler = _ref[_i];
        if (handler.route.test(path)) {
          handler.callback(path, {
            changeURL: true
          });
          return true;
        }
      }
      return false;
    };

    Router.prototype.routeHandler = function(path, callback) {
      var routed;
      routed = this.route(path);
      return typeof callback === "function" ? callback(routed) : void 0;
    };

    Router.prototype.changeURL = function(url) {
      return Backbone.history.navigate(url, {
        trigger: false
      });
    };

    Router.prototype.changeURLHandler = function(url) {
      return this.changeURL(url);
    };

    Router.prototype.disposed = false;

    Router.prototype.dispose = function() {
      if (this.disposed) return;
      this.stopHistory();
      delete Backbone.history;
      this.unsubscribeAllEvents();
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Router;

  })();

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/subscriber": function(exports, require, module) {
    (function() {
  var Subscriber, mediator;

  mediator = require('mediator');

  module.exports = Subscriber = {
    subscribeEvent: function(type, handler) {
      if (typeof type !== 'string') {
        throw new TypeError('Subscriber#subscribeEvent: ' + 'type argument must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('Subscriber#subscribeEvent: ' + 'handler argument must be a function');
      }
      mediator.unsubscribe(type, handler, this);
      return mediator.subscribe(type, handler, this);
    },
    unsubscribeEvent: function(type, handler) {
      if (typeof type !== 'string') {
        throw new TypeError('Subscriber#unsubscribeEvent: ' + 'type argument must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('Subscriber#unsubscribeEvent: ' + 'handler argument must be a function');
      }
      return mediator.unsubscribe(type, handler);
    },
    unsubscribeAllEvents: function() {
      return mediator.unsubscribe(null, null, this);
    }
  };

  if (typeof Object.freeze === "function") Object.freeze(Subscriber);

  Subscriber;

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/support": function(exports, require, module) {
    (function() {
  var support;

  module.exports = support = {
    propertyDescriptors: (function() {
      var o;
      if (!(typeof Object.defineProperty === 'function' && typeof Object.defineProperties === 'function')) {
        return false;
      }
      try {
        o = {};
        Object.defineProperty(o, 'foo', {
          value: 'bar'
        });
        return o.foo === 'bar';
      } catch (error) {
        return false;
      }
    })()
  };

  support;

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/sync_machine": function(exports, require, module) {
    (function() {
  var STATE_CHANGE, SYNCED, SYNCING, SyncMachine, UNSYNCED, event, _fn, _i, _len, _ref;

  UNSYNCED = 'unsynced';

  SYNCING = 'syncing';

  SYNCED = 'synced';

  STATE_CHANGE = 'syncStateChange';

  module.exports = SyncMachine = {
    _syncState: UNSYNCED,
    _previousSyncState: null,
    syncState: function() {
      return this._syncState;
    },
    isUnsynced: function() {
      return this._syncState === UNSYNCED;
    },
    isSynced: function() {
      return this._syncState === SYNCED;
    },
    isSyncing: function() {
      return this._syncState === SYNCING;
    },
    unsync: function() {
      var _ref;
      if ((_ref = this._syncState) === SYNCING || _ref === SYNCED) {
        this._previousSync = this._syncState;
        this._syncState = UNSYNCED;
        this.trigger(this._syncState);
        this.trigger(STATE_CHANGE);
      }
    },
    beginSync: function() {
      var _ref;
      if ((_ref = this._syncState) === UNSYNCED || _ref === SYNCED) {
        this._previousSync = this._syncState;
        this._syncState = SYNCING;
        this.trigger(this._syncState);
        this.trigger(STATE_CHANGE);
      }
    },
    finishSync: function() {
      if (this._syncState === SYNCING) {
        this._previousSync = this._syncState;
        this._syncState = SYNCED;
        this.trigger(this._syncState);
        this.trigger(STATE_CHANGE);
      }
    },
    abortSync: function() {
      if (this._syncState === SYNCING) {
        this._syncState = this._previousSync;
        this._previousSync = this._syncState;
        this.trigger(this._syncState);
        this.trigger(STATE_CHANGE);
      }
    }
  };

  _ref = [UNSYNCED, SYNCING, SYNCED, STATE_CHANGE];
  _fn = function(event) {
    return SyncMachine[event] = function(callback, context) {
      if (context == null) context = this;
      this.on(event, callback, context);
      if (this._syncState === event) return callback.call(context);
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    event = _ref[_i];
    _fn(event);
  }

  if (typeof Object.freeze === "function") Object.freeze(SyncMachine);

  SyncMachine;

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/utils": function(exports, require, module) {
    (function() {
  var mediator, utils,
    __hasProp = Object.prototype.hasOwnProperty,
    __slice = Array.prototype.slice;

  mediator = require('mediator');

  module.exports = utils = {
    beget: (function() {
      var ctor;
      if (typeof Object.create === 'function') {
        return function(obj) {
          return Object.create(obj);
        };
      } else {
        ctor = function() {};
        return function(obj) {
          ctor.prototype = obj;
          return new ctor;
        };
      }
    })(),
    camelize: (function() {
      var camelizer, regexp;
      regexp = /[-_]([a-z])/g;
      camelizer = function(match, c) {
        return c.toUpperCase();
      };
      return function(string) {
        return string.replace(regexp, camelizer);
      };
    })(),
    upcase: function(str) {
      return str.charAt(0).toUpperCase() + str.substring(1);
    },
    underscorize: (function() {
      var regexp, underscorizer;
      regexp = /[A-Z]/g;
      underscorizer = function(c) {
        return '_' + c.toLowerCase();
      };
      return function(string) {
        return string.replace(regexp, underscorizer);
      };
    })(),
    sessionStorage: (function() {
      if (window.sessionStorage && sessionStorage.getItem && sessionStorage.setItem && sessionStorage.removeItem) {
        return function(key, value) {
          if (typeof value === 'undefined') {
            value = sessionStorage.getItem(key);
            if ((value != null) && value.toString) {
              return value.toString();
            } else {
              return value;
            }
          } else {
            sessionStorage.setItem(key, value);
            return value;
          }
        };
      } else {
        return function(key, value) {
          if (typeof value === 'undefined') {
            return utils.getCookie(key);
          } else {
            utils.setCookie(key, value);
            return value;
          }
        };
      }
    })(),
    sessionStorageRemove: (function() {
      if (window.sessionStorage && sessionStorage.getItem && sessionStorage.setItem && sessionStorage.removeItem) {
        return function(key) {
          return sessionStorage.removeItem(key);
        };
      } else {
        return function(key) {
          return utils.expireCookie(key);
        };
      }
    })(),
    getCookie: function(key) {
      var end, keyPosition, start;
      keyPosition = document.cookie.indexOf("" + key + "=");
      if (keyPosition === -1) return false;
      start = keyPosition + key.length + 1;
      end = document.cookie.indexOf(';', start);
      if (end === -1) end = document.cookie.length;
      return decodeURIComponent(document.cookie.substring(start, end));
    },
    setCookie: function(key, value) {
      return document.cookie = key + '=' + encodeURIComponent(value);
    },
    expireCookie: function(key) {
      return document.cookie = "" + key + "=nil; expires=" + ((new Date).toGMTString());
    },
    loadLib: function(url, success, error, timeout) {
      var head, onload, script, timeoutHandle;
      if (timeout == null) timeout = 7500;
      head = document.head || document.getElementsByTagName('head')[0] || document.documentElement;
      script = document.createElement('script');
      script.async = 'async';
      script.src = url;
      onload = function(_, aborted) {
        if (aborted == null) aborted = false;
        if (!(aborted || !script.readyState || script.readyState === 'complete')) {
          return;
        }
        clearTimeout(timeoutHandle);
        script.onload = script.onreadystatechange = script.onerror = null;
        if (head && script.parentNode) head.removeChild(script);
        script = void 0;
        if (success && !aborted) return success();
      };
      script.onload = script.onreadystatechange = onload;
      script.onerror = function() {
        onload(null, true);
        if (error) return error();
      };
      timeoutHandle = setTimeout(script.onerror, timeout);
      return head.insertBefore(script, head.firstChild);
    },
    /*
      Wrap methods so they can be called before a deferred is resolved.
      The actual methods are called once the deferred is resolved.
    
      Parameters:
    
      Expects an options hash with the following properties:
    
      deferred
        The Deferred object to wait for.
    
      methods
        Either:
        - A string with a method name e.g. 'method'
        - An array of strings e.g. ['method1', 'method2']
        - An object with methods e.g. {method: -> alert('resolved!')}
    
      host (optional)
        If you pass an array of strings in the `methods` parameter the methods
        are fetched from this object. Defaults to `deferred`.
    
      target (optional)
        The target object the new wrapper methods are created at.
        Defaults to host if host is given, otherwise it defaults to deferred.
    
      onDeferral (optional)
        An additional callback function which is invoked when the method is called
        and the Deferred isn't resolved yet.
        After the method is registered as a done handler on the Deferred,
        this callback is invoked. This can be used to trigger the resolving
        of the Deferred.
    
      Examples:
    
      deferMethods(deferred: def, methods: 'foo')
        Wrap the method named foo of the given deferred def and
        postpone all calls until the deferred is resolved.
    
      deferMethods(deferred: def, methods: def.specialMethods)
        Read all methods from the hash def.specialMethods and
        create wrapped methods with the same names at def.
    
      deferMethods(
        deferred: def, methods: def.specialMethods, target: def.specialMethods
      )
        Read all methods from the object def.specialMethods and
        create wrapped methods at def.specialMethods,
        overwriting the existing ones.
    
      deferMethods(deferred: def, host: obj, methods: ['foo', 'bar'])
        Wrap the methods obj.foo and obj.bar so all calls to them are postponed
        until def is resolved. obj.foo and obj.bar are overwritten
        with their wrappers.
    */
    deferMethods: function(options) {
      var deferred, func, host, methods, methodsHash, name, onDeferral, target, _i, _len, _results;
      deferred = options.deferred;
      methods = options.methods;
      host = options.host || deferred;
      target = options.target || host;
      onDeferral = options.onDeferral;
      methodsHash = {};
      if (typeof methods === 'string') {
        methodsHash[methods] = host[methods];
      } else if (methods.length && methods[0]) {
        for (_i = 0, _len = methods.length; _i < _len; _i++) {
          name = methods[_i];
          func = host[name];
          if (typeof func !== 'function') {
            throw new TypeError("utils.deferMethods: method " + name + " notfound on host " + host);
          }
          methodsHash[name] = func;
        }
      } else {
        methodsHash = methods;
      }
      _results = [];
      for (name in methodsHash) {
        if (!__hasProp.call(methodsHash, name)) continue;
        func = methodsHash[name];
        if (typeof func !== 'function') continue;
        _results.push(target[name] = utils.createDeferredFunction(deferred, func, target, onDeferral));
      }
      return _results;
    },
    createDeferredFunction: function(deferred, func, context, onDeferral) {
      if (context == null) context = deferred;
      return function() {
        var args;
        args = arguments;
        if (deferred.state() === 'resolved') {
          return func.apply(context, args);
        } else {
          deferred.done(function() {
            return func.apply(context, args);
          });
          if (typeof onDeferral === 'function') return onDeferral.apply(context);
        }
      };
    },
    accumulator: {
      collectedData: {},
      handles: {},
      handlers: {},
      successHandlers: {},
      errorHandlers: {},
      interval: 2000
    },
    wrapAccumulators: function(obj, methods) {
      var func, name, _i, _len,
        _this = this;
      for (_i = 0, _len = methods.length; _i < _len; _i++) {
        name = methods[_i];
        func = obj[name];
        if (typeof func !== 'function') {
          throw new TypeError("utils.wrapAccumulators: method " + name + " not found");
        }
        obj[name] = utils.createAccumulator(name, obj[name], obj);
      }
      return $(window).unload(function() {
        var handler, name, _ref, _results;
        _ref = utils.accumulator.handlers;
        _results = [];
        for (name in _ref) {
          handler = _ref[name];
          _results.push(handler({
            async: false
          }));
        }
        return _results;
      });
    },
    createAccumulator: function(name, func, context) {
      var acc, accumulatedError, accumulatedSuccess, cleanup, id;
      if (!(id = func.__uniqueID)) {
        id = func.__uniqueID = name + String(Math.random()).replace('.', '');
      }
      acc = utils.accumulator;
      cleanup = function() {
        delete acc.collectedData[id];
        delete acc.successHandlers[id];
        return delete acc.errorHandlers[id];
      };
      accumulatedSuccess = function() {
        var handler, handlers, _i, _len;
        handlers = acc.successHandlers[id];
        if (handlers) {
          for (_i = 0, _len = handlers.length; _i < _len; _i++) {
            handler = handlers[_i];
            handler.apply(this, arguments);
          }
        }
        return cleanup();
      };
      accumulatedError = function() {
        var handler, handlers, _i, _len;
        handlers = acc.errorHandlers[id];
        if (handlers) {
          for (_i = 0, _len = handlers.length; _i < _len; _i++) {
            handler = handlers[_i];
            handler.apply(this, arguments);
          }
        }
        return cleanup();
      };
      return function() {
        var data, error, handler, rest, success;
        data = arguments[0], success = arguments[1], error = arguments[2], rest = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
        if (data) {
          acc.collectedData[id] = (acc.collectedData[id] || []).concat(data);
        }
        if (success) {
          acc.successHandlers[id] = (acc.successHandlers[id] || []).concat(success);
        }
        if (error) {
          acc.errorHandlers[id] = (acc.errorHandlers[id] || []).concat(error);
        }
        if (acc.handles[id]) return;
        handler = function(options) {
          var args, collectedData;
          if (options == null) options = options;
          if (!(collectedData = acc.collectedData[id])) return;
          args = [collectedData, accumulatedSuccess, accumulatedError].concat(rest);
          func.apply(context, args);
          clearTimeout(acc.handles[id]);
          delete acc.handles[id];
          return delete acc.handlers[id];
        };
        acc.handlers[id] = handler;
        return acc.handles[id] = setTimeout((function() {
          return handler();
        }), acc.interval);
      };
    },
    afterLogin: function() {
      var args, context, eventType, func, loginHandler;
      context = arguments[0], func = arguments[1], eventType = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
      if (eventType == null) eventType = 'login';
      if (mediator.user) {
        return func.apply(context, args);
      } else {
        loginHandler = function() {
          mediator.unsubscribe(eventType, loginHandler);
          return func.apply(context, args);
        };
        return mediator.subscribe(eventType, loginHandler);
      }
    },
    deferMethodsUntilLogin: function(obj, methods, eventType) {
      var func, name, _i, _len, _results;
      if (eventType == null) eventType = 'login';
      if (typeof methods === 'string') methods = [methods];
      _results = [];
      for (_i = 0, _len = methods.length; _i < _len; _i++) {
        name = methods[_i];
        func = obj[name];
        if (typeof func !== 'function') {
          throw new TypeError("utils.deferMethodsUntilLogin: method " + name + "not found");
        }
        _results.push(obj[name] = _(utils.afterLogin).bind(null, obj, func, eventType));
      }
      return _results;
    },
    ensureLogin: function() {
      var args, context, e, eventType, func, loginContext;
      context = arguments[0], func = arguments[1], loginContext = arguments[2], eventType = arguments[3], args = 5 <= arguments.length ? __slice.call(arguments, 4) : [];
      if (eventType == null) eventType = 'login';
      utils.afterLogin.apply(utils, [context, func, eventType].concat(__slice.call(args)));
      if (!mediator.user) {
        if ((e = args[0]) && typeof e.preventDefault === 'function') {
          e.preventDefault();
        }
        return mediator.publish('!showLogin', loginContext);
      }
    },
    ensureLoginForMethods: function(obj, methods, loginContext, eventType) {
      var func, name, _i, _len, _results;
      if (eventType == null) eventType = 'login';
      if (typeof methods === 'string') methods = [methods];
      _results = [];
      for (_i = 0, _len = methods.length; _i < _len; _i++) {
        name = methods[_i];
        func = obj[name];
        if (typeof func !== 'function') {
          throw new TypeError("utils.ensureLoginForMethods: method " + name + "not found");
        }
        _results.push(obj[name] = _(utils.ensureLogin).bind(null, obj, func, loginContext, eventType));
      }
      return _results;
    },
    modifierKeyPressed: function(event) {
      return event.shiftKey || event.altKey || event.ctrlKey || event.metaKey;
    }
  };

  if (typeof Object.seal === "function") Object.seal(utils);

  utils;

}).call(this);

  }
}));
(this.require.define({
  "chaplin/lib/view_helper": function(exports, require, module) {
    (function() {
  var mediator, utils;

  mediator = require('mediator');

  utils = require('chaplin/lib/utils');

  Handlebars.registerHelper('if_logged_in', function(options) {
    if (mediator.user) {
      return options.fn(this);
    } else {
      return options.inverse(this);
    }
  });

  Handlebars.registerHelper('with', function(context, options) {
    if (!context || Handlebars.Utils.isEmpty(context)) {
      return options.inverse(this);
    } else {
      return options.fn(context);
    }
  });

  Handlebars.registerHelper('without', function(context, options) {
    var inverse;
    inverse = options.inverse;
    options.inverse = options.fn;
    options.fn = inverse;
    return Handlebars.helpers["with"].call(this, context, options);
  });

  Handlebars.registerHelper('with_user', function(options) {
    var context;
    context = mediator.user || {};
    return Handlebars.helpers["with"].call(this, context, options);
  });

}).call(this);

  }
}));
(this.require.define({
  "chaplin/models/collection": function(exports, require, module) {
    (function() {
  var Collection, Subscriber, SyncMachine,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Subscriber = require('chaplin/lib/subscriber');

  SyncMachine = require('chaplin/lib/sync_machine');

  module.exports = Collection = (function(_super) {

    __extends(Collection, _super);

    function Collection() {
      Collection.__super__.constructor.apply(this, arguments);
    }

    _(Collection.prototype).extend(Subscriber);

    Collection.prototype.initDeferred = function() {
      return _(this).extend($.Deferred());
    };

    Collection.prototype.initSyncMachine = function() {
      return _(this).extend(SyncMachine);
    };

    Collection.prototype.addAtomic = function(models, options) {
      var batch_direction, model;
      if (options == null) options = {};
      if (!models.length) return;
      options.silent = true;
      batch_direction = typeof options.at === 'number' ? 'pop' : 'shift';
      while (model = models[batch_direction]()) {
        this.add(model, options);
      }
      return this.trigger('reset');
    };

    Collection.prototype.update = function(newList, options) {
      var fingerPrint, i, ids, model, newFingerPrint, preexistent, _ids, _len, _results;
      if (options == null) options = {};
      fingerPrint = this.pluck('id').join();
      ids = _(newList).pluck('id');
      newFingerPrint = ids.join();
      if (fingerPrint !== newFingerPrint) {
        _ids = _(ids);
        i = this.models.length - 1;
        while (i >= 0) {
          model = this.models[i];
          if (!_ids.include(model.id)) this.remove(model);
          i--;
        }
      }
      if (!(fingerPrint === newFingerPrint && !options.deep)) {
        _results = [];
        for (i = 0, _len = newList.length; i < _len; i++) {
          model = newList[i];
          preexistent = this.get(model.id);
          if (preexistent) {
            if (!options.deep) continue;
            _results.push(preexistent.set(model));
          } else {
            _results.push(this.add(model, {
              at: i
            }));
          }
        }
        return _results;
      }
    };

    Collection.prototype.disposed = false;

    Collection.prototype.dispose = function() {
      var prop, properties, _i, _len;
      if (this.disposed) return;
      this.trigger('dispose', this);
      this.unsubscribeAllEvents();
      this.off();
      this.reset([], {
        silent: true
      });
      properties = ['model', 'models', '_byId', '_byCid'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Collection;

  })(Backbone.Collection);

}).call(this);

  }
}));
(this.require.define({
  "chaplin/models/model": function(exports, require, module) {
    (function() {
  var Model, Subscriber,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Subscriber = require('chaplin/lib/subscriber');

  module.exports = Model = (function(_super) {

    __extends(Model, _super);

    function Model() {
      Model.__super__.constructor.apply(this, arguments);
    }

    _(Model.prototype).extend(Subscriber);

    Model.prototype.initDeferred = function() {
      return _(this).extend($.Deferred());
    };

    Model.prototype.getAttributes = function() {
      return this.attributes;
    };

    Model.prototype.disposed = false;

    Model.prototype.dispose = function() {
      var prop, properties, _i, _len;
      if (this.disposed) return;
      this.trigger('dispose', this);
      this.unsubscribeAllEvents();
      this.off();
      properties = ['collection', 'attributes', '_escapedAttributes', '_previousAttributes', '_silent', '_pending'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return Model;

  })(Backbone.Model);

}).call(this);

  }
}));
(this.require.define({
  "chaplin/views/application_view": function(exports, require, module) {
    (function() {
  var ApplicationView, Subscriber, mediator, utils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  mediator = require('mediator');

  utils = require('chaplin/lib/utils');

  Subscriber = require('chaplin/lib/subscriber');

  module.exports = ApplicationView = (function() {

    _(ApplicationView.prototype).extend(Subscriber);

    ApplicationView.prototype.title = '';

    function ApplicationView(options) {
      if (options == null) options = {};
      this.openLink = __bind(this.openLink, this);
      this.title = options.title;
      this.subscribeEvent('beforeControllerDispose', this.hideOldView);
      this.subscribeEvent('startupController', this.showNewView);
      this.subscribeEvent('startupController', this.removeFallbackContent);
      this.subscribeEvent('startupController', this.adjustTitle);
      this.subscribeEvent('loginStatus', this.updateBodyClasses);
      this.updateBodyClasses();
      this.addDOMHandlers();
    }

    ApplicationView.prototype.hideOldView = function(controller) {
      var view;
      scrollTo(0, 0);
      view = controller.view;
      if (view) return view.$el.css('display', 'none');
    };

    ApplicationView.prototype.showNewView = function(context) {
      var view;
      view = context.controller.view;
      if (view) {
        return view.$el.css({
          display: 'block',
          opacity: 1,
          visibility: 'visible'
        });
      }
    };

    ApplicationView.prototype.adjustTitle = function(context) {
      var subtitle, title;
      title = this.title;
      subtitle = context.controller.title;
      if (subtitle) title = "" + subtitle + " \u2013 " + title;
      return setTimeout((function() {
        return document.title = title;
      }), 50);
    };

    ApplicationView.prototype.updateBodyClasses = function(loggedIn) {
      return $(document.body).toggleClass('logged-out', !loggedIn).toggleClass('logged-in', loggedIn);
    };

    ApplicationView.prototype.removeFallbackContent = function() {
      $('.accessible-fallback').remove();
      return this.unsubscribeEvent('startupController', this.removeFallbackContent);
    };

    ApplicationView.prototype.addDOMHandlers = function() {
      return $(document).delegate('.go-to', 'click', this.goToHandler).delegate('a', 'click', this.openLink);
    };

    ApplicationView.prototype.openLink = function(event) {
      var currentHostname, el, external, hostnameRegExp, href;
      if (utils.modifierKeyPressed(event)) return;
      el = event.currentTarget;
      href = el.getAttribute('href');
      if (href === '' || href.charAt(0) === '#') return;
      currentHostname = location.hostname.replace('.', '\\.');
      hostnameRegExp = RegExp("" + currentHostname + "$", "i");
      external = !hostnameRegExp.test(el.hostname);
      if (external) return;
      return this.openInternalLink(event);
    };

    ApplicationView.prototype.openInternalLink = function(event) {
      var el, path;
      if (utils.modifierKeyPressed(event)) return;
      el = event.currentTarget;
      path = el.pathname;
      if (!path) return;
      return mediator.publish('!router:route', path, function(routed) {
        if (routed) return event.preventDefault();
      });
    };

    ApplicationView.prototype.goToHandler = function(event) {
      var el, path;
      el = event.currentTarget;
      if (event.nodeName === 'A') return;
      path = $(el).data('href');
      if (!path) return;
      return mediator.publish('!router:route', path, function(routed) {
        if (routed) {
          return event.preventDefault();
        } else {
          return location.href = path;
        }
      });
    };

    ApplicationView.prototype.disposed = false;

    ApplicationView.prototype.dispose = function() {
      if (this.disposed) return;
      this.unsubscribeAllEvents();
      delete this.title;
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return ApplicationView;

  })();

}).call(this);

  }
}));
(this.require.define({
  "chaplin/views/collection_view": function(exports, require, module) {
    (function() {
  var CollectionView, View, utils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  utils = require('lib/utils');

  View = require('chaplin/views/view');

  module.exports = CollectionView = (function(_super) {

    __extends(CollectionView, _super);

    function CollectionView() {
      this.dispose = __bind(this.dispose, this);
      this.renderAllItems = __bind(this.renderAllItems, this);
      this.showHideFallback = __bind(this.showHideFallback, this);
      this.itemsResetted = __bind(this.itemsResetted, this);
      this.itemRemoved = __bind(this.itemRemoved, this);
      this.itemAdded = __bind(this.itemAdded, this);
      this.hideLoadingIndicator = __bind(this.hideLoadingIndicator, this);
      this.showLoadingIndicator = __bind(this.showLoadingIndicator, this);
      CollectionView.__super__.constructor.apply(this, arguments);
    }

    CollectionView.prototype.animationDuration = 500;

    CollectionView.prototype.listSelector = null;

    CollectionView.prototype.$list = null;

    CollectionView.prototype.fallbackSelector = null;

    CollectionView.prototype.$fallback = null;

    CollectionView.prototype.itemSelector = null;

    CollectionView.prototype.viewsByCid = null;

    CollectionView.prototype.visibleItems = null;

    CollectionView.prototype.getView = function() {
      throw new Error('CollectionView#getView must be overridden');
    };

    CollectionView.prototype.initialize = function(options) {
      if (options == null) options = {};
      CollectionView.__super__.initialize.apply(this, arguments);
      _(options).defaults({
        render: true,
        renderItems: true,
        filterer: null
      });
      this.viewsByCid = {};
      this.visibleItems = [];
      this.addCollectionListeners();
      if (options.filterer) this.filter(options.filterer);
      if (options.render) this.render();
      if (options.renderItems) return this.renderAllItems();
    };

    CollectionView.prototype.addCollectionListeners = function() {
      this.modelBind('loadStart', this.showLoadingIndicator);
      this.modelBind('load', this.hideLoadingIndicator);
      this.modelBind('add', this.itemAdded);
      this.modelBind('remove', this.itemRemoved);
      return this.modelBind('reset', this.itemsResetted);
    };

    CollectionView.prototype.showLoadingIndicator = function() {
      if (this.collection.length) return;
      return this.$('.loading').css('display', 'block');
    };

    CollectionView.prototype.hideLoadingIndicator = function() {
      return this.$('.loading').css('display', 'none');
    };

    CollectionView.prototype.itemAdded = function(item, collection, options) {
      if (options == null) options = {};
      return this.renderAndInsertItem(item, options.index);
    };

    CollectionView.prototype.itemRemoved = function(item) {
      return this.removeViewForItem(item);
    };

    CollectionView.prototype.itemsResetted = function() {
      return this.renderAllItems();
    };

    CollectionView.prototype.render = function() {
      CollectionView.__super__.render.apply(this, arguments);
      this.$list = this.listSelector ? this.$(this.listSelector) : this.$el;
      return this.initFallback();
    };

    CollectionView.prototype.initFallback = function() {
      var f, isDeferred;
      if (!this.fallbackSelector) return;
      this.$fallback = this.$(this.fallbackSelector);
      f = 'function';
      isDeferred = typeof this.collection.done === f && typeof this.collection.state === f;
      if (!isDeferred) return;
      return this.bind('visibilityChange', this.showHideFallback);
    };

    CollectionView.prototype.showHideFallback = function() {
      var empty;
      empty = this.visibleItems.length === 0 && this.collection.state() === 'resolved';
      return this.$fallback.css('display', empty ? 'block' : 'none');
    };

    CollectionView.prototype.renderAllItems = function() {
      var cid, index, item, items, remainingViewsByCid, view, _i, _len, _len2, _ref;
      items = this.collection.models;
      this.visibleItems = [];
      remainingViewsByCid = {};
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        view = this.viewsByCid[item.cid];
        if (view) remainingViewsByCid[item.cid] = view;
      }
      _ref = this.viewsByCid;
      for (cid in _ref) {
        if (!__hasProp.call(_ref, cid)) continue;
        view = _ref[cid];
        if (!(cid in remainingViewsByCid)) this.removeView(cid, view);
      }
      for (index = 0, _len2 = items.length; index < _len2; index++) {
        item = items[index];
        view = this.viewsByCid[item.cid];
        if (view) {
          this.insertView(item, view, index, 0);
        } else {
          this.renderAndInsertItem(item, index);
        }
      }
      if (!items.length) {
        return this.trigger('visibilityChange', this.visibleItems);
      }
    };

    CollectionView.prototype.filter = function(filterer) {
      var included, index, item, view, _len, _ref;
      this.filterer = filterer;
      if (!_(this.viewsByCid).isEmpty()) {
        _ref = this.collection.models;
        for (index = 0, _len = _ref.length; index < _len; index++) {
          item = _ref[index];
          included = filterer ? filterer(item, index) : true;
          view = this.viewsByCid[item.cid];
          if (!view) continue;
          $(view.el).stop(true, true)[included ? 'show' : 'hide']();
          this.updateVisibleItems(item, included, false);
        }
      }
      return this.trigger('visibilityChange', this.visibleItems);
    };

    CollectionView.prototype.renderAndInsertItem = function(item, index) {
      var view;
      view = this.renderItem(item);
      return this.insertView(item, view, index);
    };

    CollectionView.prototype.renderItem = function(item) {
      var view;
      view = this.viewsByCid[item.cid];
      if (!view) {
        view = this.getView(item);
        this.viewsByCid[item.cid] = view;
      }
      view.render();
      return view;
    };

    CollectionView.prototype.insertView = function(item, view, index, animationDuration) {
      var $list, $viewEl, children, included, position;
      if (index == null) index = null;
      if (animationDuration == null) animationDuration = this.animationDuration;
      position = typeof index === 'number' ? index : this.collection.indexOf(item);
      included = this.filterer ? this.filterer(item, position) : true;
      $viewEl = view.$el;
      if (included) {
        if (animationDuration) $viewEl.css('opacity', 0);
      } else {
        $viewEl.css('display', 'none');
      }
      $list = this.$list;
      children = $list.children(this.itemSelector);
      if (position === 0) {
        $list.prepend($viewEl);
      } else if (position < children.length) {
        children.eq(position).before($viewEl);
      } else {
        $list.append($viewEl);
      }
      view.trigger('addedToDOM');
      this.updateVisibleItems(item, included);
      if (animationDuration && included) {
        return $viewEl.animate({
          opacity: 1
        }, animationDuration);
      }
    };

    CollectionView.prototype.removeViewForItem = function(item) {
      var view;
      this.updateVisibleItems(item, false);
      view = this.viewsByCid[item.cid];
      return this.removeView(item.cid, view);
    };

    CollectionView.prototype.removeView = function(cid, view) {
      view.dispose();
      return delete this.viewsByCid[cid];
    };

    CollectionView.prototype.updateVisibleItems = function(item, includedInFilter, triggerEvent) {
      var includedInVisibleItems, visibilityChanged, visibleItemsIndex;
      if (triggerEvent == null) triggerEvent = true;
      visibilityChanged = false;
      visibleItemsIndex = _(this.visibleItems).indexOf(item);
      includedInVisibleItems = visibleItemsIndex > -1;
      if (includedInFilter && !includedInVisibleItems) {
        this.visibleItems.push(item);
        visibilityChanged = true;
      } else if (!includedInFilter && includedInVisibleItems) {
        this.visibleItems.splice(visibleItemsIndex, 1);
        visibilityChanged = true;
      }
      if (visibilityChanged && triggerEvent) {
        this.trigger('visibilityChange', this.visibleItems);
      }
      return visibilityChanged;
    };

    CollectionView.prototype.dispose = function() {
      var cid, prop, properties, view, _i, _len, _ref;
      if (this.disposed) return;
      _ref = this.viewsByCid;
      for (cid in _ref) {
        if (!__hasProp.call(_ref, cid)) continue;
        view = _ref[cid];
        view.dispose();
      }
      properties = ['$list', '$fallback', 'viewsByCid', 'visibleItems'];
      for (_i = 0, _len = properties.length; _i < _len; _i++) {
        prop = properties[_i];
        delete this[prop];
      }
      return CollectionView.__super__.dispose.apply(this, arguments);
    };

    return CollectionView;

  })(View);

}).call(this);

  }
}));
(this.require.define({
  "chaplin/views/view": function(exports, require, module) {
    (function() {
  var Subscriber, View, utils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  utils = require('chaplin/lib/utils');

  Subscriber = require('chaplin/lib/subscriber');

  require('chaplin/lib/view_helper');

  module.exports = View = (function(_super) {
    var wrapMethod;

    __extends(View, _super);

    _(View.prototype).extend(Subscriber);

    View.prototype.autoRender = false;

    View.prototype.containerSelector = null;

    View.prototype.containerMethod = 'append';

    View.prototype.subviews = null;

    View.prototype.subviewsByName = null;

    wrapMethod = function(obj, name) {
      var func;
      func = obj[name];
      return obj[name] = function() {
        func.apply(obj, arguments);
        return obj["after" + (utils.upcase(name))].apply(obj, arguments);
      };
    };

    function View() {
      this.dispose = __bind(this.dispose, this);      if (this.initialize !== View.prototype.initialize) {
        wrapMethod(this, 'initialize');
      }
      if (this.initialize !== View.prototype.initialize) {
        wrapMethod(this, 'render');
      } else {
        this.render = _(this.render).bind(this);
      }
      View.__super__.constructor.apply(this, arguments);
    }

    View.prototype.initialize = function(options) {
      this.subviews = [];
      this.subviewsByName = {};
      if (this.model || this.collection) this.modelBind('dispose', this.dispose);
      if (this.initialize === View.prototype.initialize) {
        return this.afterInitialize();
      }
    };

    View.prototype.afterInitialize = function() {
      var autoRender;
      autoRender = this.options.autoRender != null ? this.options.autoRender : this.autoRender;
      if (autoRender) return this.render();
    };

    View.prototype.delegateEvents = function() {};

    View.prototype.delegate = function(eventType, second, third) {
      var handler, selector;
      if (typeof eventType !== 'string') {
        throw new TypeError('View#delegate: first argument must be a string');
      }
      if (arguments.length === 2) {
        handler = second;
      } else if (arguments.length === 3) {
        selector = second;
        if (typeof selector !== 'string') {
          throw new TypeError('View#delegate: ' + 'second argument must be a string');
        }
        handler = third;
      } else {
        throw new TypeError('View#delegate: ' + 'only two or three arguments are allowed');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#delegate: ' + 'handler argument must be function');
      }
      eventType += ".delegate" + this.cid;
      handler = _(handler).bind(this);
      if (selector) {
        return this.$el.on(eventType, selector, handler);
      } else {
        return this.$el.on(eventType, handler);
      }
    };

    View.prototype.undelegate = function() {
      return this.$el.unbind(".delegate" + this.cid);
    };

    View.prototype.modelBind = function(type, handler) {
      var model;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelBind: ' + 'type must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelBind: ' + 'handler argument must be function');
      }
      model = this.model || this.collection;
      if (!model) {
        throw new TypeError('View#modelBind: no model or collection set');
      }
      model.off(type, handler, this);
      return model.on(type, handler, this);
    };

    View.prototype.modelUnbind = function(type, handler) {
      var model;
      if (typeof type !== 'string') {
        throw new TypeError('View#modelUnbind: ' + 'type argument must be a string');
      }
      if (typeof handler !== 'function') {
        throw new TypeError('View#modelUnbind: ' + 'handler argument must be a function');
      }
      model = this.model || this.collection;
      if (!model) return;
      return model.off(type, handler);
    };

    View.prototype.modelUnbindAll = function() {
      var model;
      model = this.model || this.collection;
      if (!model) return;
      return model.off(null, null, this);
    };

    View.prototype.pass = function(attribute, selector) {
      var _this = this;
      return this.modelBind("change:" + attribute, function(model, value) {
        var $el;
        $el = _this.$(selector);
        if ($el.is(':input')) {
          return $el.val(value);
        } else {
          return $el.text(value);
        }
      });
    };

    View.prototype.subview = function(name, view) {
      if (name && view) {
        this.removeSubview(name);
        this.subviews.push(view);
        this.subviewsByName[name] = view;
        return view;
      } else if (name) {
        return this.subviewsByName[name];
      }
    };

    View.prototype.removeSubview = function(nameOrView) {
      var index, name, otherName, otherView, view, _ref;
      if (!nameOrView) return;
      if (typeof nameOrView === 'string') {
        name = nameOrView;
        view = this.subviewsByName[name];
      } else {
        view = nameOrView;
        _ref = this.subviewsByName;
        for (otherName in _ref) {
          otherView = _ref[otherName];
          if (view === otherView) {
            name = otherName;
            break;
          }
        }
      }
      if (!(name && view && view.dispose)) return;
      view.dispose();
      index = _(this.subviews).indexOf(view);
      if (index > -1) this.subviews.splice(index, 1);
      return delete this.subviewsByName[name];
    };

    View.prototype.getTemplateData = function() {
      var modelAttributes, templateData;
      modelAttributes = this.model && this.model.getAttributes();
      templateData = modelAttributes ? utils.beget(modelAttributes) : {};
      if (this.model && typeof this.model.state === 'function') {
        templateData.resolved = this.model.state() === 'resolved';
      }
      return templateData;
    };

    View.prototype.render = function() {
      var html, template;
      if (this.disposed) return;
      template = this.template;
      if (typeof template === 'string') {
        template = Handlebars.compile(template);
        this.template = template;
      }
      if (typeof template === 'function') {
        html = template(this.getTemplateData());
        this.$el.empty().append(html);
      }
      return this;
    };

    View.prototype.afterRender = function() {
      var container, containerMethod;
      container = this.options.container != null ? this.options.container : this.containerSelector;
      if (container) {
        containerMethod = this.options.containerMethod != null ? this.options.containerMethod : this.containerMethod;
        $(container)[containerMethod](this.el);
        this.trigger('addedToDOM');
      }
      return this;
    };

    View.prototype.disposed = false;

    View.prototype.dispose = function() {
      var prop, properties, view, _i, _j, _len, _len2, _ref;
      if (this.disposed) return;
      _ref = this.subviews;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        view = _ref[_i];
        view.dispose();
      }
      this.unsubscribeAllEvents();
      this.modelUnbindAll();
      this.off();
      this.$el.remove();
      properties = ['el', '$el', 'options', 'model', 'collection', 'subviews', 'subviewsByName'];
      for (_j = 0, _len2 = properties.length; _j < _len2; _j++) {
        prop = properties[_j];
        delete this[prop];
      }
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

    return View;

  })(Backbone.View);

}).call(this);

  }
}));
