
define(['chaplin/lib/create_mediator', 'chaplin/models/model'], function(createMediator, Model) {
  'use strict';
  var mediator;
  mediator = createMediator();
  return describe('mediator', function() {
    it('should be a simple object', function() {
      return expect(typeof mediator).toEqual('object');
    });
    it('should have Pub/Sub methods', function() {
      expect(typeof mediator.subscribe).toEqual('function');
      expect(typeof mediator.unsubscribe).toEqual('function');
      return expect(typeof mediator.publish).toEqual('function');
    });
    it('should have readonly Pub/Sub methods', function() {
      var methods;
      if (!Object.defineProperty) return;
      methods = ['subscribe', 'unsubscribe', 'publish'];
      methods.forEach(function(property) {
        return expect(function() {
          return mediator[property] = 'foo';
        }).toThrow();
      });
      if (!Object.getOwnPropertyDescriptor) return;
      return methods.forEach(function(property) {
        var desc;
        desc = Object.getOwnPropertyDescriptor(mediator, property);
        expect(desc.enumerable).toBe(true);
        expect(desc.writable).toBe(false);
        return expect(desc.configurable).toBe(false);
      });
    });
    it('should publish messages to subscribers', function() {
      var eventName, payload, spy;
      spy = jasmine.createSpy();
      eventName = 'foo';
      payload = 'payload';
      mediator.subscribe(eventName, spy);
      mediator.publish(eventName, payload);
      expect(spy).toHaveBeenCalledWith(payload);
      return mediator.unsubscribe(eventName, spy);
    });
    it('should allow to unsubscribe to events', function() {
      var eventName, payload, spy;
      spy = jasmine.createSpy();
      eventName = 'foo';
      payload = 'payload';
      mediator.subscribe(eventName, spy);
      mediator.unsubscribe(eventName, spy);
      mediator.publish(eventName, payload);
      return expect(spy).not.toHaveBeenCalledWith(payload);
    });
    it('should have a user which is null', function() {
      return expect(mediator.user).toBeNull();
    });
    it('should have a readonly user', function() {
      if (!Object.defineProperty) return;
      return expect(function() {
        return mediator.user = 'foo';
      }).toThrow();
    });
    it('should have a setUser method', function() {
      return expect(typeof mediator.setUser).toEqual('function');
    });
    return it('should have a user after calling setUser', function() {
      var user;
      user = new Model;
      mediator.setUser(user);
      return expect(mediator.user).toBe(user);
    });
  });
});
