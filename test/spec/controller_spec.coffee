define [
  'chaplin/controllers/controller'
], (Controller) ->
  'use strict'

  describe 'Controller', ->
    #console.debug 'Controller spec'

    it 'should be extendable', ->
      expect(typeof Controller.extend).toBe 'function'

      DerivedController = Controller.extend()
      derivedController = new DerivedController()
      expect(derivedController instanceof Controller).toBe true

      derivedController.dispose()

    xit 'should be tested properly', ->
