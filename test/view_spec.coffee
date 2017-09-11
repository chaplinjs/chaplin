'use strict'
$ = require 'jquery'
Backbone = require 'backbone'
sinon = require 'sinon'
{EventBroker, SyncMachine, mediator} = require '../build/chaplin'
{Collection, Model, View} = require '../build/chaplin'

describe 'View', ->
  renderCalled = false
  renderReturnValue = 'render return value'

  view = model = collection = null
  template = '<p>content</p>'

  testbed = document.createElement 'var'
  testbed.id = 'testbed'
  document.body.appendChild testbed

  beforeEach ->
    renderCalled = false
    view = new TestView()

  afterEach ->
    view.dispose()
    view = null
    if model
      model.dispose?()
      model = null
    if collection
      collection.dispose?()
      collection = null

  setModel = ->
    model = new Model foo: 'foo', bar: 'bar'
    view.model = model

  setCollection = ->
    collection = new Collection()
    view.collection = collection

  delay = (callback) ->
    window.setTimeout callback, 40

  class TestView extends View
    id: 'test-view'

    getTemplateFunction: ->
      -> template

    # Overrides super
    initialize: ->
      super

    # Overrides render
    render: ->
      super
      renderCalled = true
      return renderReturnValue

  class AutoRenderView extends TestView
    autoRender: true
    container: '#testbed'

  class ConfiguredTestView extends TestView
    autoRender: true
    container: '#testbed'
    containerMethod: if $ then 'before' else (container, el) ->
      p = container.parentNode
      p.insertBefore el, container

  it 'should mixin a EventBroker', ->
    prototype = View.prototype
    expect(prototype).to.contain.all.keys EventBroker

  it 'should render', ->
    expect(view).to.respondTo 'render'
    renderResult = view.render()
    expect(renderResult).to.be.equal renderReturnValue

  it 'should render a template', ->
    view.render()
    innerHTML = view.el.innerHTML.toLowerCase()
    lowerCaseTemplate = template.toLowerCase()
    expect(innerHTML).to.equal lowerCaseTemplate

  it 'should render automatically', ->
    view = new TestView autoRender: true
    expect(renderCalled).to.be.true
    # should not be in the DOM
    expect(view.el.parentNode).to.be.null

  it 'should not render without proper getTemplateFunction', ->
    expect(-> new View autoRender: true).to.throw Error

  it 'should attach itself to an element automatically', ->
    view = new TestView container: testbed
    expect(renderCalled).to.be.false
    # Expect that the view is attached to the DOM *on first render*,
    # not immediately after initialize
    expect(view.el.parentNode).to.be.null
    view.render()
    expect(view.el.parentNode).to.equal testbed

  it 'should attach itself to a selector automatically', ->
    view = new TestView container: '#testbed'
    view.render()
    expect(view.el.parentNode).to.equal testbed

  it 'should attach itself to a jQuery object automatically', ->
    return unless $

    view = new TestView container: $ '#testbed'
    view.render()
    expect(view.el.parentNode).to.equal testbed

  it 'should use the given attach method', ->
    customContainerMethod = (container, el) ->
      p = container.parentNode
      p.insertBefore el, container.nextSibling
    containerMethod = if $ then 'after' else customContainerMethod
    view = new TestView {container: testbed, containerMethod}
    view.render()
    expect(view.el).to.equal testbed.nextSibling
    expect(view.el.parentNode).to.equal testbed.parentNode

  it 'should consider autoRender, container and containerMethod properties', ->
    view = new ConfiguredTestView()
    expect(renderCalled).to.be.true
    expect(view.el).to.equal testbed.previousSibling
    expect(view.el.parentNode).to.equal testbed.parentNode

  it 'should not attach itself more than once', ->
    spy = sinon.spy testbed, 'appendChild'
    view = new TestView container: testbed
    view.render()
    view.render()
    expect(spy).to.have.been.calledOnce

  it 'should not attach itself if autoAttach is false', ->
    class NoAutoAttachView1 extends View
      autoAttach: false
      autoRender: true
      container: testbed
      getTemplateFunction: TestView::getTemplateFunction
      attach: sinon.spy()

    class NoAutoAttachView2 extends TestView
      autoAttach: false
      autoRender: true
      container: testbed
      attach: sinon.spy()

    view1 = new NoAutoAttachView1
    expect(view1.attach).to.not.have.been.called
    expect(view1.el.parentNode).to.be.null

    view2 = new NoAutoAttachView2
    expect(view2.attach).to.not.have.been.called
    expect(view2.el.parentNode).to.be.null

  it 'should not wrap el with `tagName` when using a region', ->
    mediator.setHandler 'region:register', ->
    mediator.setHandler 'region:show', ->
    mediator.setHandler 'region:find', ->

    view1 = class Test1View extends View
      autoRender: true
      container: testbed
      getTemplateFunction: ->
        -> '<main><div id="test0"></div></main>'
      regions:
        'region1': '#test0'

    view2 = class Test2View extends View
      autoRender: true
      region: 'region1'
      tagName: 'section'
      noWrap: true
      regions:
        'test1': '#test1'
      getTemplateFunction: ->
        -> '<div><p>View is not wrapped!</p><p id="test1">foo</p></div>'

    instance1 = new Test1View()
    instance2 = new Test2View()
    expect(instance2.el.parentElement.querySelector 'section').to.be.null

    instance1.dispose()
    instance2.dispose()

  it 'should not wrap el with `tagName`', ->
    viewWrap = class Test3View extends View
      autoRender: true
      tagName: 'section'
      noWrap: yes
      container: testbed
      getTemplateFunction: ->
        -> '<div><p>View is not wrapped!</p><p>baz</p></div>'

    instance1 = new Test3View()
    expect(instance1.el.parentElement.querySelector 'section').to.be.null

    instance1.dispose()

  it 'should fire an addedToDOM event attching itself to the DOM', ->
    view = new TestView container: testbed
    spy = sinon.spy()
    view.on 'addedToDOM', spy
    view.render()
    expect(spy).to.have.been.calledOnce

  it 'should register and remove user input event handlers', ->
    view.dispose()
    view = new TestView container: testbed
    expect(view).to.respondTo 'delegate'
    expect(view).to.respondTo 'undelegate'

    spy = sinon.spy()
    handler = view.delegate 'click', spy
    expect(handler).to.be.a 'function'
    view.render()
    view.el.click()
    expect(spy).to.have.been.calledOnce

    view.undelegate()
    view.el.click()
    expect(spy.callCount).to.equal 1

    spy = sinon.spy()
    handler = view.delegate 'click', 'p', spy
    expect(handler).to.be.a 'function'
    p = view.el.querySelector 'p'
    p.click()

    expect(spy).to.have.been.calledOnce
    expect(-> view.delegate spy).to.throw Error

    view.undelegate()
    p.click()
    expect(spy.callCount).to.equal 1

  it 'should register and remove multiple user input event handlers', ->
    spy = sinon.spy()
    handler = view.delegate 'click input', spy
    if $
      view.$el.trigger 'click'
      view.$el.trigger 'input'
    else
      view.el.dispatchEvent new MouseEvent 'click'
      view.el.dispatchEvent new Event 'input'
    expect(spy).to.have.been.calledTwice

    view.undelegate()
    if $
      view.$el.trigger 'click'
      view.$el.trigger 'input'
    else
      view.el.dispatchEvent new MouseEvent 'click'
      view.el.dispatchEvent new Event 'input'
    expect(spy).to.have.been.calledTwice

  it 'should allow undelegating one event', ->
    spy = sinon.spy()
    spy2 = sinon.spy()
    view.delegate 'click', spy
    view.delegate 'focus', spy2
    view.render()

    view.el.click()
    expect(spy).to.have.been.calledOnce
    expect(spy2).to.not.have.been.called

    view.undelegate 'click'
    view.el.dispatchEvent new Event 'focus'
    view.el.click()

    expect(spy).to.have.been.calledOnce
    expect(spy2).to.have.been.calledOnce

  it 'should check delegate parameters', ->
    expect(-> view.delegate 1, 2, 3).to.throw Error
    expect(-> view.delegate 'click', 'foo').to.throw Error
    expect(-> view.delegate 'click', 'foo', 'bar').to.throw Error
    expect(-> view.delegate 'click', 123).to.throw Error
    expect(-> view.delegate 'click', (->), 123).to.throw Error
    expect(-> view.delegate 'click', 'foo', (->), 'other').to.throw Error

  it 'should correct inheritance of events object', ->
    class A extends TestView
      autoRender: yes
      container: testbed
      getTemplateFunction: -> -> '
      <div id="a"></div>
      <div id="b"></div>
      <div id="c"></div>
      <div id="d"></div>'
      events:
        'click #a': 'a1Handler'
      a1Handler: sinon.spy()

      click: (index) ->
        @el.querySelector("##{index}").click()

    class B extends A
      events:
        'click #a': 'a2Handler'
        'click #b': 'bHandler'
      a2Handler: sinon.spy()
      bHandler: sinon.spy()

    class C extends B
      events:
        'click #a': 'a3Handler'
        'click #c': 'cHandler'
      a3Handler: sinon.spy()
      cHandler: sinon.spy()

    class D extends C
      events:
        'click #a': 'a4Handler'
        'click #d': 'dHandler'
        'click': 'globalHandler'
      a4Handler: sinon.spy()
      dHandler: sinon.spy()
      globalHandler: sinon.spy()

    d = new D()
    d.click 'a'

    for index in [1...5]
      expect(d["a#{index}Handler"]).to.have.been.calledOnce
    for index in ['b', 'c', 'd']
      expect(d["#{index}Handler"]).to.not.have.been.called
      d.click index
      expect(d["#{index}Handler"]).to.have.been.calledOnce

    expect(d.globalHandler.callCount).to.equal 4

  it 'should allow events to be passed as a function', ->
    class E extends TestView
      events: ->
        'click': 'handler'
      handler: sinon.spy()

    e = new E()
    e.el.click()

    expect(e.handler).to.have.been.calledOnce
    expect(e.handler).to.have.been.calledOn e

  it 'should allow "listen" to be passed as a function', ->
    class E extends TestView
      listen: ->
        'test': 'handler'
      handler: sinon.spy()

    e = new E()
    e.trigger 'test'

    expect(e.handler).to.have.been.calledOnce
    expect(e.handler).to.have.been.calledOn e

  it 'should add and return subviews', ->
    expect(view).to.respondTo 'subview'

    subview = new View()
    view.subview 'fooSubview', subview
    expect(view.subview 'fooSubview').to.equal subview
    expect(view.subviews).to.have.lengthOf 1

    subview2 = new View()
    view.subview 'fooSubview', subview2
    expect(view.subview 'fooSubview').to.equal subview2
    expect(view.subviews).to.have.lengthOf 1

  it 'should remove subviews', ->
    expect(view).to.respondTo 'removeSubview'

    # By name
    subview = new View()
    view.subview 'fooSubview', subview

    view.removeSubview 'fooSubview'
    expect(view.subview 'fooSubview').to.be.undefined
    expect(view.subviews).to.empty

    # By view
    subview = new View()
    view.subview 'barSubview', subview

    view.removeSubview subview
    expect(view.subview 'barSubview').to.be.undefined
    expect(view.subviews).to.be.empty

    # Fail silently.
    view.removeSubview ''
    expect(view.subviews).to.be.empty

  it 'should return empty template data without a model', ->
    templateData = view.getTemplateData()
    expect(templateData).to.be.an 'object'
    expect(Object.keys templateData).to.be.empty

  it 'should return proper template data for a Chaplin model', ->
    setModel()
    templateData = view.getTemplateData()
    expect(templateData).to.be.an 'object'
    expect(templateData.foo).to.equal 'foo'
    expect(templateData.bar).to.equal 'bar'

  it 'should return template data that protects the model', ->
    setModel()
    templateData = view.getTemplateData()
    templateData.qux = 'qux'
    expect(model.get 'qux').to.be.undefined

  it 'should return proper template data for a Backbone model', ->
    model = new Backbone.Model foo: 'foo', bar: 'bar'
    view.model = model
    templateData = view.getTemplateData()
    expect(templateData).to.be.an 'object'
    expect(templateData.foo).to.equal 'foo'
    expect(templateData.bar).to.equal 'bar'

  it 'should return proper template data for Chaplin collections', ->
    model1 = new Model foo: 'foo'
    model2 = new Model bar: 'bar'
    collection = new Collection [model1, model2]
    view.collection = collection

    data = view.getTemplateData()
    expect(data).to.be.an 'object'
    expect(data).to.have.all.keys 'items', 'length'
    expect(data).to.have.lengthOf 2

    items = data.items
    expect(items).to.be.an 'array'
    expect(items).to.have.lengthOf 2
    expect(items).to.deep.equal [
      {'foo'}
      {'bar'}
    ]

  it 'should return proper template data for Backbone collections', ->
    model1 = new Backbone.Model foo: 'foo'
    model2 = new Backbone.Model bar: 'bar'
    collection = new Backbone.Collection [model1, model2]
    view.collection = collection

    data = view.getTemplateData()
    expect(data).to.be.an 'object'
    expect(data).to.have.all.keys 'items', 'length'
    expect(data).to.have.lengthOf 2

    items = data.items
    expect(items).to.be.an 'array'
    expect(items).to.have.lengthOf 2
    expect(items).to.deep.equal [
      {'foo'}
      {'bar'}
    ]

  it 'should add the SyncMachine state to the template data', ->
    setModel()
    Object.assign model, SyncMachine
    templateData = view.getTemplateData()
    expect(templateData.synced).to.be.false
    model.beginSync()
    model.finishSync()
    templateData = view.getTemplateData()
    expect(templateData.synced).to.be.true

  it 'should not cover existing SyncMachine properties', ->
    setModel()
    Object.assign model, SyncMachine
    model.set syncState: 'foo', synced: 'bar'
    templateData = view.getTemplateData()
    expect(templateData.syncState).to.equal 'foo'
    expect(templateData.synced).to.equal 'bar'

  it 'should pass model attributes to the template function', ->
    setModel()

    sinon.spy(view, 'getTemplateData')

    passedTemplateData = null
    templateFunc = sinon.stub().returns template
    sinon.stub(view, 'getTemplateFunction').returns templateFunc

    view.render()
    expect(view.getTemplateFunction).to.have.been.calledOnce
    expect(view.getTemplateData).to.have.been.calledOnce
    expect(templateFunc).to.have.been.calledOnce

    [templateData] = templateFunc.lastCall.args
    expect(templateData).to.deep.equal {
      'foo', 'bar'
    }

  describe 'Events', ->

    class EventedViewParent extends View
      listen:
        # self
        'ns:a': 'a1Handler'
        'ns:b': ->
          @b1Handler arguments...

        # model
        'change:a model': 'a1Handler'
        'change:b model': 'b1Handler'

        # collection
        'reset collection': 'a1Handler'
        'custom collection': 'b1Handler'

        # mediator
        'ns:a mediator': 'a1Handler'
        'ns:b mediator': 'b1Handler'

      initialize: ->
        super
        @a1Handler = sinon.spy()
        @b1Handler = sinon.spy()

    class EventedView extends EventedViewParent
      listen:
        # self
        'ns:a': 'a2Handler'
        'ns:b': ->
          @b2Handler arguments...

        # model
        'change:a model': 'a2Handler'
        'change:b model': 'b2Handler'

        # collection
        'reset collection': 'a2Handler'
        'custom collection': 'b2Handler'

        # mediator
        'ns:a mediator': 'a2Handler'
        'ns:b mediator': 'b2Handler'

      initialize: ->
        super
        @a2Handler = sinon.spy()
        @b2Handler = sinon.spy()

    it 'should bind to own events declaratively', ->
      model = new Model()
      view = new EventedView {model}

      expect(view.a1Handler).to.not.have.been.called
      expect(view.a2Handler).to.not.have.been.called
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      view.trigger 'ns:a'
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      view.trigger 'ns:b'
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.have.been.calledOnce
      expect(view.b2Handler).to.have.been.calledOnce

    it 'should bind to model events declaratively', ->
      model = new Model()
      view = new EventedView {model}

      expect(view.a1Handler).to.not.have.been.called
      expect(view.a2Handler).to.not.have.been.called
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      model.set 'a', 1
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      model.set 'b', 2
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.have.been.calledOnce
      expect(view.b2Handler).to.have.been.calledOnce

    it 'should bind to collection events declaratively', ->
      collection = new Collection()
      view = new EventedView {collection}

      expect(view.a1Handler).to.not.have.been.called
      expect(view.a2Handler).to.not.have.been.called
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      collection.reset [{a: 1}]
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      collection.trigger 'custom'
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.have.been.calledOnce
      expect(view.b2Handler).to.have.been.calledOnce

    it 'should bind to mediator events declaratively', ->
      view = new EventedView()

      expect(view.a1Handler).to.not.have.been.called
      expect(view.a2Handler).to.not.have.been.called
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      mediator.publish 'ns:a'
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.not.have.been.called
      expect(view.b2Handler).to.not.have.been.called

      mediator.publish 'ns:b'
      expect(view.a1Handler).to.have.been.calledOnce
      expect(view.a2Handler).to.have.been.calledOnce
      expect(view.b1Handler).to.have.been.calledOnce
      expect(view.b2Handler).to.have.been.calledOnce

    it 'should throw an error when corresponding method doesn’t exist', ->
      class ErrorView extends View
        listen:
          'stuff': 'stuff'

      class Error2View extends ConfiguredTestView
        events:
          'stuff': 'stuff'

      expect(-> new ErrorView).to.throw Error
      expect(-> new Error2View).to.throw Error

    it 'should allow passing params to delegateEvents', ->
      spy = sinon.spy()
      view = new AutoRenderView()
      view.delegateEvents 'click p': spy
      view.el.querySelector('p').click()

      expect(spy).to.have.been.calledOnce

    # Events hash
    # -----------

    it 'should register event handlers on the document declaratively', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      class PreservedView extends TestView
        autoRender: true
        container: 'body'
        keepElement: true
        events:
          'click p': 'testClickHandler'
          click: spy2
        testClickHandler: spy1
      view = new PreservedView()
      parent = view.el
      el = parent.querySelector 'p'
      el.click()
      expect(spy1).to.have.been.calledOnce
      expect(spy2).to.have.been.calledOnce
      view.dispose()
      el.click()
      expect(spy1.callCount).to.equal 1
      expect(spy2.callCount).to.equal 1
      parent.parentNode.removeChild parent

    it 'should register event handlers on the document programatically', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      class PreservedView extends TestView
        autoRender: true
        container: 'body'
        keepElement: true
      view = new PreservedView()
      view.testClickHandler = spy1
      view.delegateEvents
        'click p': 'testClickHandler'
        click: spy2
      parent = view.el
      el = parent.querySelector 'p'
      el.click()
      expect(spy1).to.have.been.calledOnce
      expect(spy2).to.have.been.calledOnce
      view.undelegateEvents()
      el.click()
      expect(spy1.callCount).to.equal 1
      expect(spy2.callCount).to.equal 1
      parent.parentNode.removeChild parent

  describe 'Disposal', ->

    it 'should dispose itself correctly', ->
      expect(view.disposed).to.be.false
      expect(view).to.respondTo 'dispose'
      view.dispose()

      expect(view.disposed).to.be.true
      expect(view).to.be.frozen

    it 'should remove itself from the DOM', ->
      view.el.id = 'disposed-view'
      document.body.appendChild view.el
      expect(document.querySelector '#disposed-view').to.be.ok
      view.dispose()
      expect(document.querySelector '#disposed-view').to.be.null

    it 'should call Backbone.View#remove', ->
      sinon.spy view, 'remove'
      view.dispose()
      expect(view.remove).to.have.been.calledOnce

    it 'should dispose subviews', ->
      subview = new View()
      sinon.spy subview, 'dispose'

      view.subview 'foo', subview
      view.dispose()

      expect(subview.disposed).to.be.true
      expect(subview.dispose).to.have.been.calledOnce

    it 'should unsubscribe from Pub/Sub events', ->
      spy = sinon.spy()
      view.subscribeEvent 'foo', spy
      view.dispose()

      mediator.publish 'foo'
      expect(spy).to.not.have.been.called

    it 'should unsubscribe from model events', ->
      setModel()
      spy = sinon.spy()

      view.listenTo view.model, 'foo', spy
      view.dispose()

      model.trigger 'foo'
      expect(spy).to.not.have.been.called

    it 'should remove all event handlers from itself', ->
      spy = sinon.spy()


      view.on 'foo', spy
      view.dispose()
      view.trigger 'foo'

      expect(spy).to.not.have.been.called

    it 'should remove instance properties', ->
      view.dispose()

      keys = [
        'el', '$el',
        'options', 'model', 'collection',
        'subviews', 'subviewsByName',
        '_callbacks'
      ]

      for key in keys
        expect(view).not.to.have.ownProperty key

    it 'should dispose itself when the model is disposed', ->
      model = new Model()
      view = new TestView {model}
      model.dispose()
      expect(model.disposed).to.be.true
      expect(view.disposed).to.be.true

    it 'should dispose itself when the collection is disposed', ->
      collection = new Collection()
      view = new TestView {collection}
      collection.dispose()
      expect(collection.disposed).to.be.true
      expect(view.disposed).to.be.true

    it 'should not dispose itself when the collection model is disposed', ->
      collection = new Collection [{a: 1}, {a: 2}, {a: 3}]
      view = new TestView {collection}
      collection.at(0).dispose()
      expect(collection.disposed).to.be.false
      expect(view.disposed).to.be.false

    it 'should not render when disposed given render wasn’t overridden', ->
      # Vanilla View which doesn’t override render
      view = new View()
      view.getTemplateFunction = TestView::getTemplateFunction
      sinon.spy view, 'attach'
      renderResult = view.render()
      expect(renderResult).to.equal view

      view.dispose()

      renderResult = view.render()
      expect(renderResult).to.be.false
      expect(view.attach).to.have.been.calledOnce

    it 'should not render when disposed given render was overridden', ->
      initial = testbed.children.length
      view = new TestView container: '#testbed'
      sinon.spy view, 'attach'
      renderResult = view.render()
      expect(renderResult).to.equal renderReturnValue
      expect(view.attach).to.have.been.calledOnce
      expect(renderCalled).to.be.true
      expect(view.el.parentNode).to.equal testbed

      view.dispose()

      renderResult = view.render()
      expect(renderResult).to.be.false
      # Render was called but super call should not do anything
      expect(renderCalled).to.be.true
      expect(testbed.children).have.lengthOf initial
      expect(view.attach).to.have.been.calledOnce
