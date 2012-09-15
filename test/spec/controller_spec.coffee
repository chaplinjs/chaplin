define [
  'underscore'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/controllers/controller'
  'chaplin/models/model'
  'chaplin/views/view'
], (_, mediator, EventBroker, Controller, Model, View) ->
  'use strict'

  describe 'Controller', ->
    #console.debug 'Controller spec'

    controller = null

    beforeEach ->
      controller = new Controller()

    afterEach ->
      controller.dispose()

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(controller[name]).to.equal EventBroker[name]

    it 'should redirect to a URL', ->
      expect(controller.redirectTo).to.be.a 'function'

      routerRoute = sinon.spy()
      mediator.subscribe '!router:route', routerRoute

      url = 'redirect-target/123'
      controller.redirectTo url

      expect(controller.redirected).to.be.ok()
      expect(routerRoute).was.called()
      expect(routerRoute.lastCall.args[0]).to.equal url

    it 'should redirect to a controller action', ->
      startupController = sinon.spy()
      mediator.subscribe '!startupController', startupController

      controllerName = 'redirect-controller'
      action = 'redirect-action'
      params = redirectParams: true
      controller.redirectTo controllerName, action, params

      expect(controller.redirected).to.be.ok()
      expect(startupController).was.calledWith(
        controllerName, action, params
      )

    it 'should dispose itself correctly', ->
      expect(controller.dispose).to.be.a 'function'
      controller.dispose()

      expect(controller.disposed).to.be.ok()
      if Object.isFrozen
        expect(Object.isFrozen(controller)).to.be.ok()

    it 'should dispose disposable properties', ->
      model = controller.model = new Model()
      view = controller.view = new View model: model

      controller.dispose()

      expect(_(controller).has 'model').to.not.be.ok()
      expect(_(controller).has 'view').to.not.be.ok()

      expect(model.disposed).to.be.ok()
      expect(view.disposed).to.be.ok()

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()
      controller.subscribeEvent 'foo', pubSubSpy

      controller.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).was.notCalled()

    it 'should be extendable', ->
      expect(Controller.extend).to.be.a 'function'

      DerivedController = Controller.extend()
      derivedController = new DerivedController()
      expect(derivedController).to.be.a Controller

      derivedController.dispose()
