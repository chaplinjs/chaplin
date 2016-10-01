'use strict'

$ = require 'jquery'

sinon = require 'sinon'
chai = require 'chai'
chai.use require 'sinon-chai'
chai.should()

{expect} = chai
{Controller, mediator, Layout, View} = require '../src/chaplin'

describe 'Layout', ->
  # Initialize shared variables
  layout = testController = router = null
  template2 = -> -> '<div id="test1"></div><div id="test2"></div>'
  template5 = -> -> '<div id="test1"></div><div id="test5"></div>'

  preventDefault = (event) -> event.preventDefault()

  body = document.body
  body.addEventListener 'click', preventDefault

  create = (attrs, tag = 'a') ->
    link = document.createElement tag
    for key in Object.keys attrs
      link.setAttribute key, attrs[key]
    link

  clickAndRemove = (link) ->
    icon = link.appendChild document.createElement 'i'
    body.appendChild link
    icon.click()
    body.removeChild link

  expectWasRouted = (attrs) ->
    spy = sinon.spy()
    mediator.setHandler 'router:route', spy

    clickAndRemove create arguments...
    spy.should.have.been.calledOnce

    href = attrs.href or attrs['data-href']
    [passedPath] = spy.firstCall.args
    expect(passedPath).to.deep.equal url: href

    mediator.unsubscribe '!router:route', spy
    spy

  expectWasNotRouted = ->
    spy = sinon.spy()
    mediator.setHandler 'router:route', spy
    clickAndRemove create arguments...

    spy.should.not.have.been.called
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
    body.removeEventListener 'click', preventDefault

  it 'should have el, $el and $ props / methods', ->
    expect(layout.el).to.equal document.body
    return unless $

    expect(layout.$).to.equal View::$
    expect(layout.$el).to.be.an.instanceof $

  it 'should set the document title', ->
    spy = sinon.spy()
    mediator.subscribe 'adjustTitle', spy
    mediator.execute 'adjustTitle', testController.title
    title = "#{testController.title} \u2013 #{layout.title}"
    expect(document.title).to.equal title
    spy.should.have.been.calledWith testController.title, title

  # Default routing options
  # -----------------------

  it 'should route clicks on internal links', ->
    expectWasRouted href: '/internal/link'

  it 'should correctly pass the query string', ->
    path = '/internal/link'
    query = 'foo=bar&baz=qux'

    expectWasRouted href: "#{path}?#{query}"

  it 'should not route links without href attributes', ->
    expectWasNotRouted name: 'foo'

  it 'should not route links with empty href', ->
    expectWasNotRouted href: ''

  it 'should not route links to document fragments', ->
    expectWasNotRouted href: '#foo'

  it 'should not route links with a noscript class', ->
    expectWasNotRouted href: '/foo', class: 'noscript'

  it 'should not route `rel=external` links', ->
    expectWasNotRouted href: '/foo', rel: 'external'

  it 'should not route `target=_blank` links', ->
    expectWasNotRouted href: '/foo', target: '_blank'

  it 'should not route non-http(s) links', ->
    expectWasNotRouted href: 'mailto:a@a.com'
    expectWasNotRouted href: 'javascript:1+1'
    expectWasNotRouted href: 'tel:1488'

  it 'should not route clicks on [download] links', ->
    expectWasNotRouted href: '/hello.pdf', download: 'hello.pdf'

  it 'should not route clicks on [download=""] links', ->
    expectWasNotRouted href: '/hello.pdf', download: ''

  it 'should not route clicks on external links', ->
    old = window.open
    window.open = sinon.spy()
    expectWasNotRouted href: 'http://example.com/'
    expectWasNotRouted href: 'https://example.com/'

    window.open.should.not.have.been.called
    window.open = old

  it 'should route clicks on elements with the `go-to` class', ->
    attrs = {'class': 'go-to', 'data-href': '/internal/link'}
    expectWasRouted attrs, 'span'

  # With custom external checks
  # ---------------------------

  it 'custom isExternalLink receives link properties', ->
    stub = sinon.stub().returns true
    layout.isExternalLink = stub
    expectWasNotRouted
      rel: 'external'
      href: 'http://www.example.org:1234/foo?bar=1#baz'
      target: '_blank'

    stub.should.have.been.calledOnce
    [link] = stub.lastCall.args
    expect(link).to.include
      rel: 'external'
      host: 'www.example.org:1234'
      pathname: '/foo'
      hash: '#baz'
      target: '_blank'

  it 'custom `isExternalLink` should not route if true', ->
    layout.isExternalLink = -> true
    expectWasNotRouted href: '/foo'

  it 'custom `isExternalLink` should route if false', ->
    layout.isExternalLink = -> false
    expectWasRouted href: '/foo', rel: 'external'

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
    window.open.should.have.been.calledOnce

    window.open = sinon.stub()
    layout.dispose()
    layout = new Layout title: '', openExternalToBlank: true
    expectWasNotRouted href: '/foo', rel: 'external'

    window.open.should.have.been.calledOnce
    window.open = old

  it 'skipRouting=false should route links with a `noscript` class', ->
    layout.dispose()
    layout = new Layout title: '', skipRouting: false
    expectWasRouted href: '/foo', class: 'noscript'

  it 'skipRouting=function should decide whether to route', ->
    path = '/foo'

    stub = sinon.stub().returns false
    layout.dispose()
    layout = new Layout title: '', skipRouting: stub
    expectWasNotRouted href: path

    stub.should.have.been.calledOnce
    args = stub.lastCall.args
    expect(args[0]).to.equal path
    expect(args[1].nodeName).to.equal 'A'

    stub = sinon.stub().returns true
    layout.dispose()
    layout = new Layout title: '', skipRouting: stub
    expectWasRouted href: path

    stub.should.have.been.calledOnce
    expect(args[0]).to.equal path
    expect(args[1].nodeName).to.equal 'A'

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
    spy.should.have.been.calledWith instance1, 'view-region1', ''
    spy.should.have.been.calledWith instance1, 'test1', '#test1'
    spy.should.have.been.calledWith instance1, 'test2', '#test2'
    expect(layout.globalRegions).to.deep.equal [
      {instance: instance1, name: 'test2', selector: '#test2'}
      {instance: instance1, name: 'test1', selector: '#test1'}
      {instance: instance1, name: 'view-region1', selector: ''}
    ]

    instance2 = new Test2View()
    spy.should.have.been.calledWith instance2, 'view-region2', ''
    spy.should.have.been.calledWith instance2, 'test3', '#test1'
    spy.should.have.been.calledWith instance2, 'test4', '#test2'
    expect(layout.globalRegions).to.deep.equal [
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

    expect(regional.globalRegions).to.deep.equal [
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
    expect(layout.globalRegions).to.deep.equal []

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

    expect(layout.globalRegions).to.deep.equal [
      {instance: instance1, name: 'test2', selector: '#test2'}
      {instance: instance1, name: 'test1', selector: '#test1'}
    ]

    instance1.dispose()

  it 'should allow for views to be applied to regions', ->
    view1 = class Test1View extends View
      autoRender: yes
      getTemplateFunction: template2
      regions:
        test0: ''
        test1: '#test1'
        test2: '#test2'

    view2 = class Test2View extends View
      autoRender: yes
      getTemplateFunction: -> # Do nothing

    instance1 = new Test1View()
    instance2 = new Test2View {region: 'test2'}
    instance3 = new Test2View {region: 'test0'}

    if $
      expect(instance2.container.prop 'id').to.equal 'test2'
      expect(instance3.container).to.equal instance1.$el
    else
      expect(instance2.container.id).to.equal 'test2'
      expect(instance3.container).to.equal instance1.el

    instance1.dispose()
    instance2.dispose()

  it 'should apply regions in the order they were registered', ->
    view1 = class Test1View extends View
      autoRender: yes
      getTemplateFunction: template2
      regions:
        'test1': '#test1'
        'test2': '#test2'

    view2 = class Test2View extends View
      autoRender: yes
      getTemplateFunction: template5
      regions:
        'test1': '#test1'
        'test2': '#test5'

    view3 = class Test3View extends View
      autoRender: yes
      getTemplateFunction: -> # Do nothing

    instance1 = new Test1View()
    instance2 = new Test2View()
    instance3 = new Test3View region: 'test2'

    id = if $
      instance3.container.prop 'id'
    else
      instance3.container.id

    expect(id).to.equal 'test5'

    instance1.dispose()
    instance2.dispose()
    instance3.dispose()

  it 'should only apply regions from non-stale views', ->
    view1 = class Test1View extends View
      autoRender: yes
      getTemplateFunction: template2
      regions:
        'test1': '#test1'
        'test2': '#test2'

    view2 = class Test2View extends View
      autoRender: yes
      getTemplateFunction: template2
      regions:
        'test1': '#test1'
        'test2': '#test5'

    view3 = class Test3View extends View
      autoRender: yes
      getTemplateFunction: -> # Do nothing

    instance1 = new Test1View()
    instance2 = new Test2View()
    instance2.stale = true
    instance3 = new Test3View {region: 'test2'}

    id = if $
      instance3.container.prop 'id'
    else
      instance3.container.id

    expect(id).to.equal 'test2'

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

    expect(layout.disposed).to.be.true
    expect(layout).to.be.frozen

    mediator.publish 'foo'

    # It should unsubscribe from events
    spy1.should.not.have.been.called
    spy2.should.not.have.been.called

  it 'should be extendable', ->
    expect(Layout.extend).to.be.a 'function'

    DerivedLayout = Layout.extend()
    derivedLayout = new DerivedLayout()
    expect(derivedLayout).to.be.an.instanceof Layout

    derivedLayout.dispose()
