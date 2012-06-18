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


    # Routing
    # =======

    describe 'with default routing params', ->
      spy = null

      beforeEach ->
        spy = jasmine.createSpy()
        mediator.subscribe '!router:route', spy

      afterEach ->
        mediator.unsubscribe '!router:route', spy

      it 'should route clicks on internal links', ->
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

      it 'should not route links without href attributes', ->
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

      it 'should not route links with empty href', ->
        # Technically an empty string is a valid relative URL
        # but it doesn’t make sense to route it
        $('<a href="">Hello World</a>')
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

      it 'should not route links to document fragments', ->
        $('<a href="#foo">Hello World</a>')
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

      it 'should not route links with a noscript class', ->
        $('<a href="/leave-the-app" class="noscript">Hello World</a>')
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

      it 'should not route links with a target="_blank" attribute', ->
        $('<a href="/leave-the-app" target="_blank">Hello World</a>')
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

      it 'should open external links in a new window', ->
        $("<a href='http://www.example.org/'>Hello World</a>")
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

    describe 'with routing param', ->
      spy = null

      beforeEach ->
        spy = jasmine.createSpy()
        mediator.subscribe '!router:route', spy
        layout.dispose()

      afterEach ->
        mediator.unsubscribe '!router:route', spy

      it 'routeLinks=false should NOT route clicks on internal links', ->
        layout = new Layout
          title: 'Test Site Title'
          routeLinks: false
        $("<a href='/an/internal/link'>Hello World</a>")
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

      it 'openExternalToBlank=false should NOT route clicks on external links', ->
        layout = new Layout
          title: 'Test Site Title'
          openExternalToBlank: false
        $("<a href='http://www.example.org/'>Hello World</a>")
          .appendTo(document.body)
          .click()
          .remove()
        expect(spy).not.toHaveBeenCalled()

      it 'skipRouting=false should route links with a noscript class', ->
        layout = new Layout
          title: 'Test Site Title'
          skipRouting: false
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


    # Events hash
    # ===========
    it 'should register event handlers on the document declaratively', ->
      spy1 = jasmine.createSpy()
      spy2 = jasmine.createSpy()
      layout.dispose()
      class TestLayout extends Layout
        events:
          'click #testbed': 'testClickHandler'
          click: spy2
        testClickHandler: spy1
      layout = new TestLayout
      el = $('#testbed')
      el.click()
      expect(spy1).toHaveBeenCalled()
      expect(spy2).toHaveBeenCalled()
      layout.dispose()
      el.click()
      expect(spy1.callCount).toBe 1
      expect(spy2.callCount).toBe 1

    it 'should register event handlers on the document programatically', ->
      expect(layout.delegateEvents is Backbone.View::delegateEvents)
        .toBe true
      expect(layout.undelegateEvents is Backbone.View::undelegateEvents)
        .toBe true
      expect(typeof layout.delegateEvents).toBe 'function'
      expect(typeof layout.undelegateEvents).toBe 'function'

      spy1 = jasmine.createSpy()
      spy2 = jasmine.createSpy()
      layout.testClickHandler = spy1
      layout.delegateEvents
        'click #testbed': 'testClickHandler'
        click: spy2
      el = $('#testbed')
      el.click()
      expect(spy1).toHaveBeenCalled()
      expect(spy2).toHaveBeenCalled()
      layout.undelegateEvents()
      el.click()
      expect(spy1.callCount).toBe 1
      expect(spy2.callCount).toBe 1

    it 'should dispose itself correctly', ->
      spy1 = jasmine.createSpy()
      layout.subscribeEvent 'foo', spy1

      spy2 = jasmine.createSpy()
      layout.delegateEvents 'click #testbed': spy2

      expect(typeof layout.dispose).toBe 'function'
      layout.dispose()

      expect(layout.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(layout)).toBe true

      mediator.publish 'foo'
      $('#testbed').click()

      # It should unsubscribe from events
      expect(spy1).not.toHaveBeenCalled()
      expect(spy2).not.toHaveBeenCalled()

    it 'should be extendable', ->
      expect(typeof Layout.extend).toBe 'function'

      DerivedLayout = Layout.extend()
      derivedLayout = new DerivedLayout()
      expect(derivedLayout instanceof Layout).toBe true

      derivedLayout.dispose()
