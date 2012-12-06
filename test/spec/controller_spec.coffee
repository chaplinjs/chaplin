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

    it 'should throw an error when redirected to a non-route', ->
      routerRoute = sinon.spy()
      mediator.subscribe '!router:route', routerRoute

      controller.redirectTo 'redirect-target/123'

      callback = routerRoute.firstCall.args[2]
      expect(callback).to.be.a 'function'
      expect(-> callback(true)).not.to.throwError()
      expect(-> callback(false)).to.throwError()

      mediator.unsubscribe '!router:route', routerRoute

    it 'should redirect to a controller action', ->
      startupController = sinon.spy()
      mediator.subscribe '!startupController', startupController

      controllerName = 'redirect-controller'
      action = 'redirect-action'
      params = redirectParams: true
      options = redirectOptions: true
      controller.redirectTo controllerName, action, params, options

      expect(controller.redirected).to.be true
      expect(startupController).was.calledWith(
        controllerName, action, params, options
      )

      mediator.unsubscribe '!startupController', startupController

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

    describe 'Configure', ->
      describe 'Before filters', ->
        
        BaseController = Controller.extend
          before:
            'user*': 'checkSession'
           
          checkSession: ->
            userModel = isAdmin: -> true

        SecureController = BaseController.extend
          before:
            '*Admin*': (params, userModel) ->
              unless userModel.isAdmin()
                @redirectTo '500'

        it 'should configure the instance to extend before filters correctly', ->
          AdminController = SecureController.extend
            before:
              'userAdminShow': null

            userAdminShow: ->
          
          controller = new AdminController()
          expect(controller.before).to.only.have.keys 'user*', '*Admin*', 'userAdminShow'

