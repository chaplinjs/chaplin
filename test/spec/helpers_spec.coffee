define [
  'chaplin/lib/helpers'
  'chaplin/mediator'
], (helpers, mediator) ->
  'use strict'

  describe 'helpers', ->
    describe 'reverse', ->
      beforeEach ->
        mediator.unsubscribe()
      afterEach ->
        mediator.unsubscribe()

      it 'should return the url for a named route', ->
        stubbedRouteHandler = (routeName, params) ->
          expect(routeName).to.be 'foo'
          expect(params).to.eql {id: 3, d: "data"}
          '/foo/bar'
        mediator.setHandler 'router:reverse', stubbedRouteHandler

        url = helpers.reverse 'foo', id: 3, d: "data"
        expect(url).to.be '/foo/bar'

      it 'should return the url for a named route with empty path', ->
        stubbedRouteHandler = (routeName, params) ->
          expect(routeName).to.be 'home'
          expect(params).to.be undefined
          '/'
        mediator.setHandler 'router:reverse', stubbedRouteHandler

        url = helpers.reverse 'home'
        expect(url).to.be '/'

      it 'should throw exception if no route found', ->
        stubbedRouteHandler = (routeName, params) ->
          false
        mediator.setHandler 'router:reverse', stubbedRouteHandler

        try
          url = helpers.reverse 'foo', id: 3, d: "data"
        catch err
          expect(err).to.be.an Error

      # it 'should return null if router does not respond', ->
      #   url = helpers.reverse 'foo', id: 3, d: "data"
      #   expect(url).to.be null
