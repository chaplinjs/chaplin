define [
  'jquery'
  'chaplin/mediator'
  'chaplin/lib/router'
  'chaplin/controllers/controller'
  'chaplin/views/layout'
  'chaplin/views/view'
], ($, mediator, Router, Controller, Layout, View) ->
  'use strict'

  describe 'Layout', ->
    # Initialize shared variables
    layout = testController = startupControllerContext = router = null

    beforeEach ->
      # Create the layout
      layout = new Layout title: 'Test Site Title'

      # Create a test controller
      testController = new Controller()
      testController.view = new View()
      testController.title = 'Test Controller Title'

      # Payload for startupController event
      startupControllerContext =
        previousControllerName: 'null'
        controller: testController
        controllerName: 'test'
        params: {}

      # Create a fresh router
      router = new Router root: '/test/'

    afterEach ->
      layout.dispose()
      testController.dispose()
      router.dispose()

    it 'should hide the view of an inactive controller', ->
      testController.view.$el.css 'display', 'block'
      mediator.publish 'beforeControllerDispose', testController
      expect(testController.view.$el.css('display')).toBe 'none'

    it 'should show the view of the active controller', ->
      testController.view.$el.css 'display', 'none'
      mediator.publish 'startupController', startupControllerContext
      $el = testController.view.$el
      expect($el.css('display')).toBe 'block'
      expect($el.css('opacity')).toBe '1'
      expect($el.css('visibility')).toBe 'visible'

    it 'should set the document title', ->
      runs ->
        mediator.publish 'startupController', startupControllerContext
      waits 100
      runs ->
        title = "#{testController.title} \u2013 #{layout.title}"
        expect(document.title).toBe title

    it 'should set logged-in/logged-out body classes', ->
      $body = $(document.body).attr('class', '')

      mediator.publish 'loginStatus', true
      expect($body.attr('class')).toBe 'logged-in'

      mediator.publish 'loginStatus', false
      expect($body.attr('class')).toBe 'logged-out'

    it 'should route clicks on internal links', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = '/an/internal/link'
      $("<a href='#{path}'>Hello World</a>")
        .appendTo(document.body)
        .click()
        .remove()
      args = spy.mostRecentCall.args
      passedPath = args[0]
      passedCallback = args[1]
      expect(passedPath).toBe path
      expect(typeof passedCallback).toBe 'function'

    it 'should correctly pass the query string', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = '/another/link?foo=bar&baz=qux'
      $("<a href='#{path}'>Hello World</a>")
        .appendTo(document.body)
        .click()
        .remove()
      args = spy.mostRecentCall.args
      passedPath = args[0]
      passedCallback = args[1]
      expect(passedPath).toBe path
      expect(typeof passedCallback).toBe 'function'
      mediator.unsubscribe '!router:route', spy

    it 'should not route links without href attributes', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a name="foo">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a>Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route links with empty href', ->
      # Technically an empty string is a valid relative URL
      # but it doesn’t make sense to route it
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a href="">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route links to document fragments', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a href="#foo">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route links with a noscript class', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      $('<a href="/leave-the-app" class="noscript">Hello World</a>')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should not route clicks on external links', ->
      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = 'http://www.example.org/'
      $("<a href='#{path}'>Hello World</a>")
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should be disposable', ->
      expect(typeof layout.dispose).toBe 'function'
      layout.dispose()

      expect(layout.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(layout)).toBe true
