
define(['chaplin/lib/create_mediator', 'chaplin/models/model', 'chaplin/lib/support'], function(createMediator, Model, support) {
  'use strict';
  var mediator;
  mediator = createMediator({
    createUserProperty: true
  });
  return describe('mediator', function() {
    it('should be a simple object', function() {
      return expect(typeof mediator).toBe('object');
    });
    it('should have Pub/Sub methods', function() {
      expect(typeof mediator.subscribe).toBe('function');
      expect(typeof mediator.unsubscribe).toBe('function');
      return expect(typeof mediator.publish).toBe('function');
    });
    it('should have readonly Pub/Sub methods', function() {
      var methods;
      if (!(support.propertyDescriptors && Object.getOwnPropertyDescriptor)) {
        return;
      }
      methods = ['subscribe', 'unsubscribe', 'publish'];
      return _(methods).forEach(function(property) {
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
      if (!support.propertyDescriptors) return;
      return expect(function() {
        return mediator.user = 'foo';
      }).toThrow();
    });
    it('should have a setUser method', function() {
      return expect(typeof mediator.setUser).toBe('function');
    });
    return it('should have a user after calling setUser', function() {
      var user;
      user = new Model;
      mediator.setUser(user);
      return expect(mediator.user).toBe(user);
    });
  });
});
