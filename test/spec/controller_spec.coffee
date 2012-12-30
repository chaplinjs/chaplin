define [
  'underscore'
  'backbone'
  'chaplin/mediator'
  'chaplin/lib/event_broker'
  'chaplin/controllers/controller'
  'chaplin/models/model'
  'chaplin/views/view'
], (_, Backbone, mediator, EventBroker, Controller, Model, View) ->
  'use strict'

  describe 'Controller', ->
    controller = null

    beforeEach ->
      controller = new Controller()

    afterEach ->
      controller.dispose()

    it 'should mixin a Backbone.Events', ->
      for own name, value of Backbone.Events
        expect(controller[name]).to.be Backbone.Events[name]

    it 'should mixin an EventBroker', ->
      for own name, value of EventBroker
        expect(controller[name]).to.be EventBroker[name]

    it 'should redirect to a URL', ->
      expect(controller.redirectTo).to.be.a 'function'

      routerRoute = sinon.spy()
      mediator.subscribe '!router:route', routerRoute

      url = 'redirect-target/123'
      controller.redirectTo url

      expect(controller.redirected).to.be true
      expect(routerRoute).was.calledWith url

      mediator.unsubscribe '!router:route', routerRoute

    it 'should redirect to a URL with routing options', ->
      routerRoute = sinon.spy()
      mediator.subscribe '!router:route', routerRoute

      url = 'redirect-target/123'
      options = replace: true
      controller.redirectTo url, options

      expect(controller.redirected).to.be true
      expect(routerRoute).was.calledWith url, options

      mediator.unsubscribe '!router:route', routerRoute

    it 'should throw an error when redirected to a non-route', ->
      routerRoute = sinon.spy()
      mediator.subscribe '!router:route', routerRoute

      controller.redirectTo 'redirect-target/123'

      callback = routerRoute.firstCall.args[2]
      expect(callback).to.be.a 'function'
      expect(-> callback(true)).not.to.throwError()
      expect(-> callback(false)).to.throwError()

      mediator.unsubscribe '!router:route', routerRoute

    it 'should dispose itself correctly', ->
      expect(controller.dispose).to.be.a 'function'
      controller.dispose()

      expect(controller.disposed).to.be true
      if Object.isFrozen
        expect(Object.isFrozen(controller)).to.be true

    it 'should dispose disposable properties', ->
      model = controller.model = new Model()
      view = controller.view = new View model: model

      controller.dispose()

      expect(controller).not.to.have.own.property 'model'
      expect(controller).not.to.have.own.property 'view'

      expect(model.disposed).to.be true
      expect(view.disposed).to.be true

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
