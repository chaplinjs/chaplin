define [
  'underscore'
  'chaplin/mediator'
  'chaplin/application'
  'chaplin/lib/router'
  'chaplin/dispatcher'
  'chaplin/composer'
  'chaplin/views/layout'
  'chaplin/lib/event_broker'
], (_, mediator, Application, Router, Dispatcher, Composer, Layout, EventBroker) ->
  'use strict'

  describe 'Application', ->
    app = new Application()

    it 'should be a simple object', ->
      expect(app).to.be.an 'object'
      expect(app).to.be.a Application

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(app[name]).to.be EventBroker[name]

    it 'should initialize', ->
      expect(app.initialize).to.be.a 'function'
      app.initialize()

    it 'should create a dispatcher', ->
      expect(app.initDispatcher).to.be.a 'function'
      app.initDispatcher()
      expect(app.dispatcher).to.be.a Dispatcher

    it 'should create a layout', ->
      expect(app.initLayout).to.be.a 'function'
      app.initLayout()
      expect(app.layout).to.be.a Layout

    it 'should create a composer', ->
      expect(app.initComposer).to.be.a 'function'
      app.initComposer()
      expect(app.composer).to.be.a Composer

    it 'should create a router', ->
      passedMatch = null
      routesCalled = false
      routes = (match) ->
        routesCalled = true
        passedMatch = match

      expect(app.initRouter).to.be.a 'function'
      expect(app.initRouter.length).to.be 2
      app.initRouter routes, root: '/', pushState: false

      expect(app.router).to.be.a Router
      expect(routesCalled).to.be true
      expect(passedMatch).to.be.a 'function'

    it 'should not start Backbone.history', ->
      expect(Backbone.History.started).to.be false

    it 'should dispose itself correctly', ->
      expect(app.dispose).to.be.a 'function'
      app.dispose()

      for prop in ['dispatcher', 'layout', 'router', 'composer']
        expect(app).not.to.have.own.property prop

      expect(app.disposed).to.be true
      if Object.isFrozen
        expect(Object.isFrozen(app)).to.be true

    it 'should be extendable', ->
      expect(Application.extend).to.be.a 'function'

      DerivedApplication = Application.extend()
      derivedApp = new DerivedApplication()
      expect(derivedApp).to.be.a Application

      derivedApp.dispose()
