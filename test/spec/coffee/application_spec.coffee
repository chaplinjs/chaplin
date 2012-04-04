define [
    'mediator', 'application', 'lib/router',
    'controllers/session_controller', 'controllers/application_controller'
], (mediator, Application, Router, SessionController, ApplicationController) ->
  'use strict'

  describe 'Application', ->
    #console.debug 'Application spec'

    it 'should be a simple object', ->
      expect(typeof Application).toEqual 'object'

    it 'should initialize', ->
      expect(typeof Application.initialize).toBe 'function'
      Application.initialize()

    it 'should create a session controller', ->
      expect(Application.sessionController instanceof SessionController)
        .toEqual true

    it 'should create an application controller', ->
      expect(Application.applicationController instanceof ApplicationController)
        .toEqual true

    it 'should create a router on the mediator', ->
      expect(mediator.router instanceof Router).toEqual true

    it 'should start Backbone.history', ->
      expect(Backbone.History.started).toBe true

    it 'should be frozen', ->
      return unless Object.isFrozen
      expect(Object.isFrozen(Application)).toBe true
