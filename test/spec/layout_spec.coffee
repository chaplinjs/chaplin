define [
  'jquery'
  'underscore'
  'chaplin/mediator'
  'chaplin/controllers/controller'
  'chaplin/views/layout'
  'chaplin/views/view'
], ($, _, mediator, Controller, Layout, View) ->
  'use strict'

  describe 'Layout', ->
    # Initialize shared variables
    layout = testController = router = null
    template = -> -> '<div id="test1"></div><div id="test2"></div>'
    template5 = -> -> '<div id="test1"></div><div id="test5"></div>'

    preventDefault = (event) -> event.preventDefault()
    document.body.addEventListener 'click', preventDefault unless $

    omit = (object, excluded) ->
      result = {}
      for key, value of object when key isnt excluded
        result[key] = value
      result

    createLink = (attributes) ->
      attributes = if attributes then _.extend {}, attributes else {}
      # Yes, this is ugly. We’re doing it because IE8-10 reports an incorrect
      # protocol if the href attribute is set programatically.
      if attributes.href?
        div = document.createElement 'div'
        div.innerHTML = "<a href='#{attributes.href}'>Hello World</a>"
        link = div.firstChild
        attributes = omit attributes, 'href'
      else
        link = document.createElement 'a'
      for key, value of attributes
        link.setAttribute key, value
      link

    appendClickRemove = (element) ->
      document.body.appendChild element
      if $
        $(element).click()
      else
        element.click()
      document.body.removeChild element

    expectWasRouted = (linkAttributes) ->
      stub = sinon.spy()
      mediator.setHandler 'router:route', stub
      appendClickRemove createLink linkAttributes
      expect(stub).was.calledOnce()
      [passedPath] = stub.firstCall.args
      expect(passedPath).to.eql url: linkAttributes.href
      mediator.unsubscribe '!router:route', stub
      stub

    expectWasNotRouted = (linkAttributes) ->
      spy = sinon.spy()
      mediator.setHandler 'router:route', spy
      appendClickRemove createLink linkAttributes
      expect(spy).was.notCalled()
      mediator.unsubscribe '!router:route', spy
      spy

    beforeEach ->
      # Create the layout
      layout = new Layout title: 'Test Site Title'

      # Create a test controller
      testController = new Controller()
      testController.view = new View()
      testController.title = 'Test Controller Title'

    afterEach ->
      testController.dispose()
      layout.dispose()

    after ->
      document.body.removeEventListener 'click', preventDefault unless $

    it 'should have el, $el and $ props / methods', ->
      expect(layout.el).to.be document.body
      expect(layout.$el).to.be.a $ if $

    it 'should set the document title', (done) ->
      spy = sinon.spy()
      mediator.subscribe 'adjustTitle', spy
      mediator.execute 'adjustTitle', testController.title
      setTimeout ->
        title = "#{testController.title} \u2013 #{layout.title}"
        expect(document.title).to.be title
        expect(spy).was.calledWith testController.title, title
        done()
      , 60

    # Default routing options
    # -----------------------

    it 'should route clicks on internal links', ->
      expectWasRouted href: '/internal/link'

    it 'should correctly pass the query string', ->
      path = '/internal/link'
      query = 'foo=bar&baz=qux'

      stub = sinon.spy()
      mediator.setHandler 'router:route', stub
      linkAttributes = href: "#{path}?#{query}"
      appendClickRemove createLink linkAttributes
      expect(stub).was.calledOnce()
      [passedPath] = stub.firstCall.args
      expect(passedPath).to.eql url: linkAttributes.href
      mediator.unsubscribe '!router:route', stub

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
      old = window.open
      window.open = sinon.stub()
      expectWasNotRouted href: 'http://example.com/'
      expectWasNotRouted href: 'https://example.com/'
      expect(window.open).was.notCalled()
      window.open = old

    it 'should route clicks on elements with the “go-to” class', ->
      stub = sinon.stub()
      mediator.setHandler 'router:route', stub
      path = '/internal/link'
      span = document.createElement 'span'
      span.className = 'go-to'
      span.setAttribute 'data-href', path
      appendClickRemove span
      expect(stub).was.calledOnce()
      passedPath = stub.firstCall.args[0]
      expect(passedPath).to.eql url: path
      mediator.unsubscribe '!router:route', stub

    # With custom external checks
    # ---------------------------

    it 'custom isExternalLink receives link properties', ->
      stub = sinon.stub().returns true
      layout.isExternalLink = stub
      expectWasNotRouted href: 'http://www.example.org:1234/foo?bar=1#baz', target: "_blank", rel: "external"

      expect(stub).was.calledOnce()
      link = stub.lastCall.args[0]
      expect(link.target).to.be "_blank"
      expect(link.rel).to.be "external"
      expect(link.hash).to.be "#baz"
      expect(link.pathname.replace(/^\//, '')).to.be "foo"
      expect(link.host).to.be "www.example.org:1234"

    it 'custom isExternalLink should not route if true', ->
      layout.isExternalLink = -> true
      expectWasNotRouted href: '/foo'

    it 'custom isExternalLink should route if false', ->
      layout.isExternalLink = -> false
      expectWasRouted href: '/foo', rel: "external"

    # With custom routing options
    # ---------------------------

    it 'routeLinks=false should NOT route clicks on internal links', ->
      layout.dispose()
      layout = new Layout title: '', routeLinks: false
      expectWasNotRouted href: '/internal/link'

    it 'openExternalToBlank=true should open external links in a new tab', ->
      old = window.open

      window.open = sinon.stub()
      layout.dispose()
      layout = new Layout title: '', openExternalToBlank: true
      expectWasNotRouted href: 'http://www.example.org/'
      expect(window.open).was.called()

      window.open = sinon.stub()
      layout.dispose()
      layout = new Layout title: '', openExternalToBlank: true
      expectWasNotRouted href: '/foo', rel: "external"
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

    # Regions
    # -------

    it 'should allow for views to register regions', ->
      view1 = class Test1View extends View
        regions:
          'view-region1': ''
          'test1': '#test1'
          'test2': '#test2'

      view2 = class Test2View extends View
        regions:
          'view-region2': ''
          'test3': '#test1'
          'test4': '#test2'

      spy = sinon.spy(layout, 'registerGlobalRegion')
      instance1 = new Test1View()
      expect(spy).was.calledWith instance1, 'view-region1', ''
      expect(spy).was.calledWith instance1, 'test1', '#test1'
      expect(spy).was.calledWith instance1, 'test2', '#test2'
      expect(layout.globalRegions).to.eql [
        {instance: instance1, name: 'test2', selector: '#test2'}
        {instance: instance1, name: 'test1', selector: '#test1'}
        {instance: instance1, name: 'view-region1', selector: ''}
      ]

      instance2 = new Test2View()
      expect(spy).was.calledWith instance2, 'view-region2', ''
      expect(spy).was.calledWith instance2, 'test3', '#test1'
      expect(spy).was.calledWith instance2, 'test4', '#test2'
      expect(layout.globalRegions).to.eql [
        {instance: instance2, name: 'test4', selector: '#test2'}
        {instance: instance2, name: 'test3', selector: '#test1'}
        {instance: instance2, name: 'view-region2', selector: ''}
        {instance: instance1, name: 'test2', selector: '#test2'}
        {instance: instance1, name: 'test1', selector: '#test1'}
        {instance: instance1, name: 'view-region1', selector: ''}
      ]

      instance1.dispose()
      instance2.dispose()

    it 'should allow for itself to register regions', ->
      Regional = Layout.extend
        regions:
          'view-region1': ''
          'test1': '#test1'
          'test2': '#test2'

      regional = new Regional

      expect(regional.globalRegions).to.eql [
        {instance: regional, name: 'test2', selector: '#test2'}
        {instance: regional, name: 'test1', selector: '#test1'}
        {instance: regional, name: 'view-region1', selector: ''}
      ]

      regional.dispose()

    it 'should dispose of regions when a view is disposed', ->
      view = class TestView extends View
        regions:
          'test0': ''
          'test1': '#test1'
          'test2': '#test2'

      instance = new TestView()
      instance.dispose()
      expect(layout.globalRegions).to.eql []

    it 'should only dispose of regions a view registered when
        it is disposed', ->
      view1 = class Test1View extends View
        regions:
          'test1': '#test1'
          'test2': '#test2'

      view2 = class Test2View extends View
        regions:
          'test3': '#test1'
          'test4': '#test2'
          'test5': ''

      instance1 = new Test1View()
      instance2 = new Test2View()
      instance2.dispose()
      expect(layout.globalRegions).to.eql [
        {instance: instance1, name: 'test2', selector: '#test2'}
        {instance: instance1, name: 'test1', selector: '#test1'}
      ]
      instance1.dispose()

    it 'should allow for views to be applied to regions', ->
      view1 = class Test1View extends View
        autoRender: true
        getTemplateFunction: template
        regions:
          test0: ''
          test1: '#test1'
          test2: '#test2'

      view2 = class Test2View extends View
        autoRender: true
        getTemplateFunction: -> # Do nothing

      instance1 = new Test1View()
      instance2 = new Test2View {region: 'test2'}
      instance3 = new Test2View {region: 'test0'}

      if $
        expect(instance2.container.attr('id')).to.be 'test2'
        expect(instance3.container).to.be instance1.$el
      else
        expect(instance2.container.id).to.be 'test2'
        expect(instance3.container).to.be instance1.el

      instance1.dispose()
      instance2.dispose()

    it 'should apply regions in the order they were registered', ->
      view1 = class Test1View extends View
        autoRender: true
        getTemplateFunction: template
        regions:
          'test1': '#test1'
          'test2': '#test2'

      view2 = class Test2View extends View
        autoRender: true
        getTemplateFunction: template5
        regions:
          'test1': '#test1'
          'test2': '#test5'

      view3 = class Test3View extends View
        autoRender: true
        getTemplateFunction: -> # Do nothing

      instance1 = new Test1View()
      instance2 = new Test2View()
      instance3 = new Test3View {region: 'test2'}
      if $
        expect(instance3.container.attr('id')).to.be 'test5'
      else
        expect(instance3.container.id).to.be 'test5'

      instance1.dispose()
      instance2.dispose()
      instance3.dispose()

    it 'should only apply regions from non-stale views', ->
      view1 = class Test1View extends View
        autoRender: true
        getTemplateFunction: template
        regions:
          'test1': '#test1'
          'test2': '#test2'

      view2 = class Test2View extends View
        autoRender: true
        getTemplateFunction: template
        regions:
          'test1': '#test1'
          'test2': '#test5'

      view3 = class Test3View extends View
        autoRender: true
        getTemplateFunction: -> # Do nothing

      instance1 = new Test1View()
      instance2 = new Test2View()
      instance2.stale = true
      instance3 = new Test3View {region: 'test2'}
      if $
        expect(instance3.container.attr('id')).to.be 'test2'
      else
        expect(instance3.container.id).to.be 'test2'

      instance1.dispose()
      instance2.dispose()
      instance3.dispose()

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

      mediator.publish 'foo'
      document.querySelector('#testbed').click()

      # It should unsubscribe from events
      expect(spy1).was.notCalled()
      expect(spy2).was.notCalled()

    it 'should be extendable', ->
      expect(Layout.extend).to.be.a 'function'

      DerivedLayout = Layout.extend()
      derivedLayout = new DerivedLayout()
      expect(derivedLayout).to.be.a Layout

      derivedLayout.dispose()
