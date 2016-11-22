import Backbone from 'backbone'
import sinon from 'sinon'
import chai from 'chai'
import sinonChai from 'sinon-chai'
import Chaplin from '../src/chaplin'

chai.use sinonChai
chai.should()

{expect} = chai
{Controller, EventBroker, mediator, Model, View} = Chaplin

describe 'Controller', ->
  controller = null

  beforeEach ->
    controller = new Controller()

  afterEach ->
    controller.dispose()
    mediator.removeHandlers ['router:route']

  it 'should mixin a Backbone.Events', ->
    prototype = Controller.prototype
    expect(prototype).to.contain.all.keys Backbone.Events

  it 'should mixin an EventBroker', ->
    prototype = Controller.prototype
    expect(prototype).to.contain.all.keys EventBroker

  it 'should be extendable', ->
    expect(Controller.extend).to.be.a 'function'

    DerivedController = Controller.extend()
    derivedController = new DerivedController()
    expect(derivedController).to.be.an.instanceof Controller

    derivedController.dispose()

  it 'should redirect to a URL', ->
    expect(controller.redirectTo).to.be.a 'function'

    routerRoute = sinon.spy()
    mediator.setHandler 'router:route', routerRoute
    url = 'redirect-target/123'
    controller.redirectTo url

    expect(controller.redirected).to.be.true
    routerRoute.should.have.been.calledWith url

  it 'should redirect to a URL with routing options', ->
    routerRoute = sinon.spy()
    mediator.setHandler 'router:route', routerRoute

    url = 'redirect-target/123'
    options = replace: true
    controller.redirectTo url, options

    expect(controller.redirected).to.be.true
    routerRoute.should.have.been.calledWith url, options

  it 'should redirect to a named route', ->
    routerRoute = sinon.spy()
    mediator.setHandler 'router:route', routerRoute

    name = 'params'
    params = one: '21'
    pathDesc = name: name, params: params
    controller.redirectTo pathDesc

    expect(controller.redirected).to.be.true
    routerRoute.should.have.been.calledWith pathDesc

  it 'should redirect to a named route with options', ->
    routerRoute = sinon.spy()
    mediator.setHandler 'router:route', routerRoute

    name = 'params'
    params = one: '21'
    pathDesc = name: name, params: params
    options = replace: true
    controller.redirectTo pathDesc, options

    expect(controller.redirected).to.be.true
    routerRoute.should.have.been.calledWith pathDesc, options

  it 'should adjust page title', ->
    spy = sinon.spy()
    mediator.setHandler 'adjustTitle', spy
    controller.adjustTitle 'meh'

    spy.should.have.been.calledOnce
    spy.should.have.been.calledWith 'meh'

  describe 'Disposal', ->
    mediator.setHandler 'region:unregister', ->

    it 'should dispose itself correctly', ->
      expect(controller.disposed).to.be.false
      expect(controller.dispose).to.be.a 'function'
      controller.dispose()

      expect(controller.disposed).to.be.true
      expect(controller).to.be.frozen

    it 'should dispose disposable properties', ->
      model = controller.model = new Model()
      view = controller.view = new View model: model

      controller.dispose()

      expect(controller).not.to.have.ownProperty 'model'
      expect(controller).not.to.have.ownProperty 'view'

      expect(model.disposed).to.be.true
      expect(view.disposed).to.be.true

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()
      controller.subscribeEvent 'foo', pubSubSpy
      controller.dispose()

      mediator.publish 'foo'
      pubSubSpy.should.not.have.been.called

    it 'should unsubscribe from other events', ->
      spy = sinon.spy()
      model = new Model()

      controller.listenTo model, 'foo', spy
      controller.dispose()

      model.trigger 'foo'
      spy.should.not.have.been.called
