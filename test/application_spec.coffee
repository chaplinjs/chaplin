'use strict'
Backbone = require 'backbone'
{Application, Composer, Dispatcher} = require '../build/chaplin'
{EventBroker, Router, mediator, Layout} = require '../build/chaplin'

describe 'Application', ->
  app = null

  getApp = (init) ->
    if init
      Application
    else
      class extends Application
        initialize: ->

  beforeEach ->
    app = new (getApp no)

  afterEach ->
    app.dispose()

  it 'should be an instance of Application', ->
    expect(app).to.be.an.instanceof Application

  it 'should mix in a EventBroker', ->
    expect(Application.prototype).to.contain.all.keys EventBroker

  it 'should have initialize function', ->
    expect(app).to.respondTo 'initialize'
    app.initialize()

  it 'should create a dispatcher', ->
    expect(app).to.respondTo 'initDispatcher'
    app.initDispatcher()
    expect(app.dispatcher).to.be.an.instanceof Dispatcher

  it 'should create a layout', ->
    expect(app).to.respondTo 'initLayout'
    app.initLayout()
    expect(app.layout).to.be.an.instanceof Layout

  it 'should create a composer', ->
    expect(app).to.respondTo 'initComposer'
    app.initComposer()
    expect(app.composer).to.be.an.instanceof Composer

  it 'should seal mediator', ->
    expect(mediator).not.to.be.sealed
    app.initMediator()
    expect(mediator).to.be.sealed

  it 'should create a router', ->
    passedMatch = null
    routesCalled = no
    routes = (match) ->
      passedMatch = match
      routesCalled = yes

    expect(app).to.respondTo 'initRouter'
    expect(app.initRouter).to.have.lengthOf 2
    app.initRouter routes, root: '/', pushState: false

    expect(app.router).to.be.an.instanceof Router
    expect(routesCalled).to.be.true
    expect(passedMatch).to.be.a 'function'
    expect(Backbone.History.started).to.be.false

  it 'should start Backbone.history with start()', ->
    app.initRouter (->), root: '/', pushState: false
    app.start()
    expect(Backbone.History.started).to.be.true
    Backbone.history.stop()

  it 'should seal itself with start()', ->
    app.initRouter()
    app.start()
    expect(app).to.be.sealed

  it 'should throw an error on double-init', ->
    app = new (getApp yes)
    expect(-> app.initialize()).to.throw Error

  it 'should dispose itself correctly', ->
    expect(app.disposed).to.be.false
    expect(app).to.respondTo 'dispose'
    app.dispose()

    for key in ['dispatcher', 'layout', 'router', 'composer']
      expect(app).not.to.have.ownProperty key

    expect(app.disposed).to.be.true
    expect(app).to.be.frozen

  it 'should be extendable', ->
    expect(Application).itself.to.respondTo 'extend'

    DerivedApplication = Application.extend()
    derivedApp = new DerivedApplication()
    derivedApp.dispose()

    expect(derivedApp).to.be.an.instanceof Application
