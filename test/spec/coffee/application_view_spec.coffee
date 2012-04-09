define [
  'mediator',
  'chaplin/controllers/controller',
  'chaplin/views/application_view'
], (mediator, Controller, ApplicationView) ->
  'use strict'

  describe 'ApplicationView', ->
    applicationView = undefined

    # Clear the mediator
    mediator.unsubscribe()

    testController = new Controller()

    it 'should initialize', ->
      applicationView = new ApplicationView()

    xit 'should be tested more thoroughly', ->
      expect(false).toBe true