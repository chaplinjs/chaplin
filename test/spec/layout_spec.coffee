define [
  'underscore'
  'jquery'
  'backbone'
  'chaplin/mediator'
  'chaplin/controllers/controller'
  'chaplin/views/layout'
  'chaplin/views/view'
], (_, $, Backbone, mediator, Controller, Layout, View) ->
  'use strict'

  describe 'Layout', ->
    # Initialize shared variables
    layout = testController = startupControllerContext = router = null

    createLink = (attributes) ->
      attributes = if attributes then _.clone(attributes) else {}
      # Yes, this is ugly. We’re doing it because IE8-10 reports an incorrect
      # protocol if the href attribute is set programatically.
      if attributes.href?
        div = document.createElement 'div'
        div.innerHTML = "<a href='#{attributes.href}'>Hello World</a>"
        link = div.firstChild
        attributes = _.omit attributes, 'href'
        $link = $(link)
      else
        $link = $(document.createElement 'a')
      $link.attr attributes

    expectWasRouted = (linkAttributes) ->
      stub = sinon.stub().yields false
      Backbone.on '!router:route', stub
      createLink(linkAttributes).appendTo(document.body).click().remove()
      expect(stub).was.calledOnce()
      [passedPath, passedOptions, passedCallback] = stub.firstCall.args
      expect(passedPath).to.be linkAttributes.href
      expect(passedCallback).to.be.a 'function'
      Backbone.off '!router:route', stub
      stub

    expectWasNotRouted = (linkAttributes) ->
      spy = sinon.spy()
      Backbone.on '!router:route', spy
      createLink(linkAttributes).appendTo(document.body).click().remove()
      expect(spy).was.notCalled()
      Backbone.off '!router:route', spy
      spy

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

    afterEach ->
      layout.dispose()
      testController.dispose()

    it 'should hide the view of an inactive controller', ->
      testController.view.$el.css 'display', 'block'
      Backbone.trigger 'beforeControllerDispose', testController
      expect(testController.view.$el.css('display')).to.be 'none'

    it 'should show the view of the active controller', ->
      testController.view.$el.css 'display', 'none'
      Backbone.trigger 'startupController', startupControllerContext
      $el = testController.view.$el
      expect($el.css('display')).to.be 'block'
      expect($el.css('opacity')).to.be '1'
      expect($el.css('visibility')).to.be 'visible'

    it 'should set the document title', (done) ->
      Backbone.trigger '!adjustTitle', testController.title
      setTimeout ->
        title = "#{testController.title} \u2013 #{layout.title}"
        expect(document.title).to.be title
        done()
      , 60

    # Default routing options
    # -----------------------

    it 'should route clicks on internal links', ->
      expectWasRouted href: '/an/internal/link'

    it 'should correctly pass the query string', ->
      expectWasRouted href: '/another/link?foo=bar&baz=qux'

    it 'should not route links without href attributes', ->
      expectWasNotRouted name: 'foo'

    it 'should not route links with empty href', ->
      expectWasNotRouted href: ''

    it 'should not route links to document fragments', ->
      expectWasNotRouted href: '#foo'

    it 'should not route links with a noscript class', ->
      expectWasNotRouted href: '/foo', class: 'noscript'

    it 'should not route rel=external links', ->
      expectWasNotRouted href: '/foo', rel: 'external'

    it 'should not route target=blank links', ->
      expectWasNotRouted href: '/foo', target: '_blank'

    it 'should not route non-http(s) links', ->
      expectWasNotRouted href: 'mailto:a@a.com'
      expectWasNotRouted href: 'javascript:1+1'
      expectWasNotRouted href: 'tel:1488'

    it 'should not route clicks on external links', ->
      # IE8 workaround.
      old = window.open
      window.open = sinon.stub()
      expectWasNotRouted href: 'http://example.com/'
      expectWasNotRouted href: '//example.com/'
      expectWasNotRouted href: 'https://example.com/'
      expect(window.open).was.notCalled()
      window.open = old

    it 'should route clicks on elements with the “go-to” class', ->
      stub = sinon.stub().yields true
      Backbone.on '!router:route', stub
      path = '/an/internal/link'
      $span = $(document.createElement 'span')
        .addClass('go-to').attr('data-href', path)
        .appendTo(document.body).click().remove()
      expect(stub).was.calledOnce()
      [passedPath, passedOptions, passedCallback] = stub.firstCall.args
      expect(passedPath).to.be path
      expect(passedOptions).to.be.an 'object'
      expect(passedCallback).to.be.a 'function'
      Backbone.off '!router:route', stub

    # With custom routing options
    # ---------------------------

    it 'routeLinks=false should NOT route clicks on internal links', ->
      layout.dispose()
      layout = new Layout title: '', routeLinks: false
      expectWasNotRouted href: '/an/internal/link'

    it 'openExternalToBlank=true should open external links in a new tab', ->
      old = window.open
      window.open = sinon.stub()
      layout.dispose()
      layout = new Layout title: '', openExternalToBlank: true
      expectWasNotRouted href: 'http://www.example.org/'
      expect(window.open).was.called()
      window.open = old

    it 'skipRouting=false should route links with a noscript class', ->
      layout.dispose()
      layout = new Layout title: '', skipRouting: false
      expectWasRouted href: '/foo', class: 'noscript'

    it 'skipRouting=function should decide whether to route', ->
      path = '/foo'
      stub = sinon.stub().returns false
      layout.dispose()
      layout = new Layout title: '', skipRouting: stub
      expectWasNotRouted href: path
      expect(stub).was.calledOnce()
      args = stub.lastCall.args
      expect(args[0]).to.be path
      expect(args[1]).to.be.an 'object'
      expect(args[1].nodeName).to.be 'A'

      stub = sinon.stub().returns true
      layout.dispose()
      layout = new Layout title: '', skipRouting: stub
      expectWasRouted href: path
      expect(stub).was.calledOnce()
      expect(args[0]).to.be path
      expect(args[1]).to.be.an 'object'
      expect(args[1].nodeName).to.be 'A'

    # Events hash
    # -----------

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
      expect(spy1.callCount).to.be 1
      expect(spy2.callCount).to.be 1

    it 'should register event handlers on the document programatically', ->
      expect(layout.delegateEvents)
        .to.be Backbone.View::delegateEvents
      expect(layout.undelegateEvents)
        .to.be Backbone.View::undelegateEvents
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
      expect(spy1.callCount).to.be 1
      expect(spy2.callCount).to.be 1

    it 'should dispose itself correctly', ->
      spy1 = sinon.spy()
      layout.subscribeEvent 'foo', spy1

      spy2 = sinon.spy()
      layout.delegateEvents 'click #testbed': spy2

      expect(layout.dispose).to.be.a 'function'
      layout.dispose()

      expect(layout.disposed).to.be true
      if Object.isFrozen
        expect(Object.isFrozen(layout)).to.be true

      Backbone.trigger 'foo'
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
