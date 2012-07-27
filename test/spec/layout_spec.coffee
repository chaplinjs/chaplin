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
      router = new Router()
      
      @testLink = (callback) ->
        spy = sinon.spy()
        mediator.subscribe '!router:route', spy
        link = $('<a>').text('Hello World')
        callback(link)
        link.appendTo(document.body).click().remove()
        expect(spy).was.notCalled()
        mediator.unsubscribe '!router:route', spy

    afterEach ->
      layout.dispose()
      testController.dispose()
      router.dispose()

    it 'should hide the view of an inactive controller', ->
      testController.view.$el.css 'display', 'block'
      mediator.publish 'beforeControllerDispose', testController
      expect(testController.view.$el.css('display')).to.equal 'none'

    it 'should show the view of the active controller', ->
      testController.view.$el.css 'display', 'none'
      mediator.publish 'startupController', startupControllerContext
      $el = testController.view.$el
      expect($el.css('display')).to.equal 'block'
      expect($el.css('opacity')).to.equal '1'
      expect($el.css('visibility')).to.equal 'visible'

    it 'should set the document title', (done) ->
      mediator.publish 'startupController', startupControllerContext
      setTimeout ->
        title = "#{testController.title} \u2013 #{layout.title}"
        expect(document.title).to.equal title
        done()
      , 100

    it 'should route clicks on internal links', ->
      spy = sinon.spy()
      mediator.subscribe '!router:route', spy
      path = '/an/internal/link'
      a = $('<a>').attr('href', path).text('Hello World')
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).was.called()
      args = spy.lastCall.args
      passedPath = args[0]
      passedCallback = args[1]
      expect(passedPath).to.equal path
      expect(passedCallback).to.be.a 'function'

    it 'should correctly pass the query string', ->
      spy = sinon.spy()
      mediator.subscribe '!router:route', spy
      path = '/another/link?foo=bar&baz=qux'
      $('<a>').attr('href', path).text('Hello World')
        .appendTo(document.body)
        .click()
        .remove()
      args = spy.lastCall.args
      passedPath = args[0]
      passedCallback = args[1]
      expect(passedPath).to.equal path
      expect(passedCallback).to.be.a 'function'
      mediator.unsubscribe '!router:route', spy

    it 'should not route links without href attributes', ->
      @testLink (link) -> link.attr('name', 'foo')

    it 'should not route links with empty href', ->
      @testLink (link) -> link.attr('href', '')

    it 'should not route links to document fragments', ->
      @testLink (link) -> link.attr('href', '#foo')

    it 'should not route links with a noscript class', ->
      @testLink (link) -> link.attr('href', 'url').addClass('noscript')

    it 'should not route rel=external links', ->
      @testLink (link) -> link.attr('rel', 'external')

    it 'should not route target=blank links', ->
      @testLink (link) -> link.attr('target', '_blank')

    it 'should not route non-http(s) links', ->
      @testLink (link) -> link.attr('href', 'mailto:a@a.com')
      @testLink (link) -> link.attr('href', 'javascript:1+1')
      @testLink (link) -> link.attr('href', 'tel:1488')

    it 'should not route clicks on external links', ->
      @testLink (link) -> link.attr('href', 'http://example.com/')
      @testLink (link) -> link.attr('href', 'https://example.com/')

    it 'should register event handlers on the document declaratively', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      layout.dispose()
      class TestLayout extends Layout
        events:
          'click #testbed': 'testClickHandler'
          click: spy2
        testClickHandler: spy1
      layout = new TestLayout
      el = $('#testbed')
      el.click()
      expect(spy1).was.called()
      expect(spy2).was.called()
      layout.dispose()
      el.click()
      expect(spy1.callCount).to.equal 1
      expect(spy2.callCount).to.equal 1

    it 'should register event handlers on the document programatically', ->
      expect(layout.delegateEvents)
        .to.equal Backbone.View::delegateEvents
      expect(layout.undelegateEvents)
        .to.equal Backbone.View::undelegateEvents
      expect(layout.delegateEvents).to.be.a 'function'
      expect(layout.undelegateEvents).to.be.a 'function'

      spy1 = sinon.spy()
      spy2 = sinon.spy()
      layout.testClickHandler = spy1
      layout.delegateEvents
        'click #testbed': 'testClickHandler'
        click: spy2
      el = $('#testbed')
      el.click()
      expect(spy1).was.called()
      expect(spy2).was.called()
      layout.undelegateEvents()
      el.click()
      expect(spy1.callCount).to.equal 1
      expect(spy2.callCount).to.equal 1

    it 'should dispose itself correctly', ->
      spy1 = sinon.spy()
      layout.subscribeEvent 'foo', spy1

      spy2 = sinon.spy()
      layout.delegateEvents 'click #testbed': spy2

      expect(layout.dispose).to.be.a 'function'
      layout.dispose()

      expect(layout.disposed).to.be.ok()
      if Object.isFrozen
        expect(Object.isFrozen(layout)).to.be.ok()

      mediator.publish 'foo'
      $('#testbed').click()

      # It should unsubscribe from events
      expect(spy1).was.notCalled()
      expect(spy2).was.notCalled()

    it 'should be extendable', ->
      expect(Layout.extend).to.be.a 'function'

      DerivedLayout = Layout.extend()
      derivedLayout = new DerivedLayout()
      expect(derivedLayout).to.be.a Layout

      derivedLayout.dispose()
