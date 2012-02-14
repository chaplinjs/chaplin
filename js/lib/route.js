var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty;

define(['mediator'], function(mediator) {
  'use strict';
  var Route;
  return Route = (function() {

    Route.reservedParams = 'path navigate'.split(' ');

    function Route(expression, target, options) {
      var _ref;
      this.options = options != null ? options : {};
      this.handler = __bind(this.handler, this);
      this.addParamName = __bind(this.addParamName, this);
      _ref = target.split('#'), this.controller = _ref[0], this.action = _ref[1];
      this.paramNames = [];
      expression = expression.replace(/:(\w+)/g, this.addParamName);
      this.regExp = new RegExp('^' + expression + '(?=\\?|$)');
    }

    Route.prototype.addParamName = function(match, paramName) {
      if (_(Route.reservedParams).include(paramName)) {
        throw new Error("Route#new: parameter name " + paramName + " is reserved");
      }
      this.paramNames.push(paramName);
      return '([\\w-]+)';
    };

    Route.prototype.test = function(path) {
      var constraint, constraints, matches, params, type, _ref;
      matches = this.regExp.exec(path);
      if (!matches) return false;
      constraints = this.options.constraints;
      if (constraints) {
        params = this.buildParams(path, matches);
        _ref = this.constraints;
        for (type in _ref) {
          if (!__hasProp.call(_ref, type)) continue;
          constraint = _ref[type];
          if (!constraint.test(params[type])) return false;
        }
      }
      return true;
    };

    Route.prototype.handler = function(path, options) {
      var params;
      if (options == null) options = {};
      params = this.buildParams(path);
      params.navigate = options.navigate === true;
      return mediator.publish('!startupController', this.controller, this.action, params);
    };

    Route.prototype.buildParams = function(path, matches) {
      var index, match, paramName, params, _len, _ref;
      matches || (matches = this.regExp.exec(path));
      params = {};
      _ref = matches.slice(1);
      for (index = 0, _len = _ref.length; index < _len; index++) {
        match = _ref[index];
        paramName = this.paramNames[index];
        params[paramName] = match;
      }
      params.path = matches[0];
      return params;
    };

    return Route;

  })();
});
