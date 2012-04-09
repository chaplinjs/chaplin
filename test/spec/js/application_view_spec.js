
define(['mediator', 'chaplin/controllers/controller', 'chaplin/views/application_view'], function(mediator, Controller, ApplicationView) {
  'use strict';  return describe('ApplicationView', function() {
    var applicationView, testController;
    applicationView = void 0;
    mediator.unsubscribe();
    testController = new Controller();
    it('should initialize', function() {
      return applicationView = new ApplicationView();
    });
    return xit('should be tested more thoroughly', function() {
      return expect(false).toBe(true);
    });
  });
});
