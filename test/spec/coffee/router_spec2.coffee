define ['lib/create_mediator', 'mediator'], (createMediator, originalMediator) ->
  'use strict'

  mockMediator = createMediator()
  define 'mediator', () -> mockMediator

  require ['lib/router'], (Router) ->
    console.debug 'Router loaded'
    router = new Router

    describe 'Router and Route', ->
      console.debug 'describe Router and Route'
      it 'should fire a matchRoute event', ->
        matchRoute = jasmine.createSpy()
        fakeMediator.subscribe 'matchRoute', matchRoute
        router.match '', 'x#y'
        router.route '/'
        expect(matchRoute).toHaveBeenCalled()
        fakeMediator.unsubscribe 'matchRoute', matchRoute

    jasmineEnv.execute()

    define 'mediator', -> originalMediator
