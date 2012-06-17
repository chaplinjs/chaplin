define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/subscriber'
  'chaplin/controllers/controller'
  'chaplin/models/model'
  'chaplin/views/view'
], (_, mediator, Subscriber, Controller, Model, View) ->
  'use strict'

  describe 'Controller', ->
    #console.debug 'Controller spec'

    controller = null

    beforeEach ->
      controller = new Controller()

    afterEach ->
      controller.dispose()

    it 'should mixin a Subscriber', ->
      for own name, value of Subscriber
        expect(controller[name]).toBe Subscriber[name]

    it 'should redirect to a URL', ->
      expect(typeof controller.redirectTo).toBe 'function'

      routerRoute = jasmine.createSpy()
      mediator.subscribe '!router:route', routerRoute

      url = 'redirect-target/123'
      controller.redirectTo url

      expect(controller.redirected).toBe true
      expect(routerRoute).toHaveBeenCalled()
      expect(routerRoute.mostRecentCall.args[0]).toBe url

    it 'should redirect to a controller action', ->
      startupController = jasmine.createSpy()
      mediator.subscribe '!startupController', startupController

      controllerName = 'redirect-controller'
      action = 'redirect-action'
      params = redirectParams: true
      controller.redirectTo controllerName, action, params

      expect(controller.redirected).toBe true
      expect(startupController).toHaveBeenCalledWith(
        controllerName, action, params
      )

    it 'should dispose itself correctly', ->
      expect(typeof controller.dispose).toBe 'function'
      controller.dispose()

      expect(controller.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(controller)).toBe true

    it 'should dispose disposable properties', ->
      model = controller.model = new Model()
      view = controller.view = new View model: model

      controller.dispose()

      expect(_(controller).has 'model').toBe false
      expect(_(controller).has 'view').toBe false

      expect(model.disposed).toBe true
      expect(view.disposed).toBe true

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = jasmine.createSpy()
      controller.subscribeEvent 'foo', pubSubSpy

      controller.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).not.toHaveBeenCalled()
