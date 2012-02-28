define(['mediator', 'application', 'lib/router'], function (mediator, Application, Router) {
  'use strict';

  Application.initialize();

  describe('Application', function () {

    it('should be a simple object', function () {
      expect(typeof Application).toEqual('object');
    });

    it('should create a read-only router', function () {
      expect(mediator.router instanceof Router).toEqual(true);
    });

    it('should be frozen', function () {
      if (Object.isFrozen) {
        expect(Object.isFrozen(Application)).toBe(true);
      }
    });

  });
});