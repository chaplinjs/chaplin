define [
  'chaplin/mediator'
], (mediator) ->
  'use strict'

  describe 'mediator', ->
    it 'should be a simple object', ->
      expect(mediator).to.be.an 'object'
