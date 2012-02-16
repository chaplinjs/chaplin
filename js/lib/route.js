var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty;

define(['mediator'], function(mediator) {
  'use strict';
  var Route;
  return Route = (function() {

    Route.reservedParams = 'path changeURL'.split(' ');

    function Route(pattern, target, options) {
      var _ref;
      this.options = options != null ? options : {};
      this.handler = __bind(this.handler, this);
      this.addParamName = __bind(this.addParamName, this);
      this.pattern = pattern;
      _ref = target.split('#'), this.controller = _ref[0], this.action = _ref[1];
      this.paramNames = [];
      pattern = pattern.replace(/:(\w+)/g, this.addParamName);
      this.regExp = new RegExp('^' + pattern + '(?=\\?|$)');
    }

    Route.prototype.addParamName = function(match, paramName) {
      if (_(Route.reservedParams).include(paramName)) {
        throw new Error("Route#new: parameter name " + paramName + " is reserved");
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
      var params;
      params = this.extractParams(path);
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
        paramName = this.paramNames[index];
        params[paramName] = match;
      }
      return params;
    };

    return Route;

  })();
});
