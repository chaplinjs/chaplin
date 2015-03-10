define [
  'underscore'
  'jquery'
  'backbone'
  'chaplin/mediator'
  'chaplin/views/view'
  'chaplin/models/model'
  'chaplin/models/collection'
  'chaplin/lib/event_broker'
  'chaplin/lib/sync_machine'
], (_, $, Backbone, mediator, View, Model, Collection, EventBroker, SyncMachine) ->
  'use strict'

  describe 'View', ->
    renderCalled = false
    renderReturnValue = "render return value"
    view = model = collection = null
    template = '<p>content</p>'
    testbed = document.getElementById 'testbed'

    beforeEach ->
      renderCalled = false
      view = new TestView

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
      collection = new Collection
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
      for own name, value of EventBroker
        expect(view[name]).to.be EventBroker[name]

    it 'should render', ->
      expect(view.render).to.be.a 'function'
      renderResult = view.render()
      expect(renderResult).to.be.equal renderReturnValue

    it 'should render a template', ->
      view.render()
      innerHTML = view.el.innerHTML.toLowerCase()
      lowerCaseTemplate = template.toLowerCase()
      expect(innerHTML).to.be lowerCaseTemplate

    it 'should render automatically', ->
      view = new TestView autoRender: true
      expect(renderCalled).to.be true
      # should not be in the DOM
      expect(view.el.parentNode).to.be null

    it 'should not render without proper getTemplateFunction', ->
      expect(-> new View autoRender: true).to.throwError()

    it 'should attach itself to an element automatically', ->
      view = new TestView container: testbed
      expect(renderCalled).to.be false
      # Expect that the view is attached to the DOM *on first render*,
      # not immediately after initialize
      expect(view.el.parentNode).to.be null
      view.render()
      expect(view.el.parentNode).to.be testbed

    it 'should attach itself to a selector automatically', ->
      view = new TestView container: '#testbed'
      view.render()
      expect(view.el.parentNode).to.be testbed

    it 'should attach itself to a jQuery object automatically', ->
      return unless $
      view = new TestView container: $('#testbed')
      view.render()
      expect(view.el.parentNode).to.be testbed

    it 'should use the given attach method', ->
      customContainerMethod = (container, el) ->
        p = container.parentNode
        p.insertBefore el, container.nextSibling
      containerMethod = if $ then 'after' else customContainerMethod
      view = new TestView {container: testbed, containerMethod}
      view.render()
      expect(view.el).to.be testbed.nextSibling
      expect(view.el.parentNode).to.be testbed.parentNode

    it 'should consider autoRender, container and containerMethod properties', ->
      view = new ConfiguredTestView()
      expect(renderCalled).to.be true
      expect(view.el).to.be testbed.previousSibling
      expect(view.el.parentNode).to.be testbed.parentNode

    it 'should not attach itself more than once', ->
      spy = sinon.spy testbed, 'appendChild'
      view = new TestView container: testbed
      view.render()
      view.render()
      expect(spy.calledOnce).to.be true

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

      check = (view) ->
        parent = view.el.parentNode
        # In IE8 stuff will have documentFragment as parentNode.
        if parent
          expect(parent.nodeType).to.be 11
        else
          expect(parent).to.be null

      view1 = new NoAutoAttachView1
      window.view1 = view1
      expect(view1.attach).was.notCalled()
      check view1

      view2 = new NoAutoAttachView2
      expect(view2.attach).was.notCalled()
      check view2

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
      expect(instance2.el.parentElement.querySelector('section')).to.be null

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
      expect(instance1.el.parentElement.querySelector('section')).to.be null

      instance1.dispose()

    it 'should fire an addedToDOM event attching itself to the DOM', ->
      view = new TestView container: testbed
      spy = sinon.spy()
      view.on 'addedToDOM', spy
      view.render()
      expect(spy).was.called()

    it 'should register and remove user input event handlers', ->
      view.dispose()
      view = new TestView container: testbed
      expect(view.delegate).to.be.a 'function'
      expect(view.undelegate).to.be.a 'function'

      spy = sinon.spy()
      handler = view.delegate 'click', spy
      expect(handler).to.be.a 'function'
      view.render()
      window.clickOnElement view.el
      expect(spy).was.called()

      view.undelegate()
      window.clickOnElement view.el
      expect(spy.callCount).to.be 1

      spy = sinon.spy()
      handler = view.delegate 'click', 'p', spy
      expect(handler).to.be.a 'function'
      p = view.el.querySelector('p')
      window.clickOnElement p
      expect(spy).was.called()

      expect(-> view.delegate spy).to.throwError()

      view.undelegate()
      window.clickOnElement p
      expect(spy.callCount).to.be 1

    # Simulates focus event.
    simulateEvent = (target, eventName, options = {}) ->
      eventName = eventName.toLowerCase()

      if document.createEvent
        evt = document.createEvent 'HTMLEvents'
        evt.initEvent eventName, true, true
        target.dispatchEvent evt
      else
        options.clientX = 0
        options.clientY = 0
        evt = document.createEventObject()
        oEvent = _.extend evt, options
        target.fireEvent "on#{eventName}", oEvent
      target

    # it 'should register and remove multiple user input event handlers', ->
    #   spy = sinon.spy()
    #   handler = view.delegate 'click keypress', spy
    #   view.$el.trigger 'click'
    #   view.$el.trigger 'keypress'
    #   expect(spy).was.calledTwice()

    #   view.undelegate()
    #   view.$el.trigger 'click'
    #   view.$el.trigger 'keypress'
    #   expect(spy).was.calledTwice()

    it 'should allow undelegating one event', ->
      spy = sinon.spy()
      spy2 = sinon.spy()
      view.delegate 'click', spy
      view.delegate 'focus', spy2
      view.render()

      window.clickOnElement view.el
      expect(spy).was.calledOnce()
      expect(spy2).was.notCalled()

      view.undelegate 'click'
      simulateEvent view.el, 'focus'
      window.clickOnElement view.el
      expect(spy).was.calledOnce()
      expect(spy2).was.calledOnce()

    it 'should check delegate parameters', ->
      expect(-> view.delegate 1, 2, 3).to.throwError()
      expect(-> view.delegate 'click', 'foo').to.throwError()
      expect(-> view.delegate 'click', 'foo', 'bar').to.throwError()
      expect(-> view.delegate 'click', 123).to.throwError()
      # expect(-> view.delegate 'click', (->), 123).to.throwError()
      # expect(-> view.delegate 'click', 'foo', (->), 'other').to.throwError()

    it 'should correct inheritance of events object', (done) ->
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
          window.clickOnElement @el.querySelector("##{index}")

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

      bcd = ['b', 'c', 'd']
      d = new D
      d.click 'a'

      delay ->
        for index in [1...5]
          expect(d["a#{index}Handler"]).was.calledOnce()
        for index in bcd
          expect(d["#{index}Handler"]).was.notCalled()
          d.click(index)
        delay ->
          for index in bcd
            expect(d["#{index}Handler"]).was.calledOnce()
          expect(d.globalHandler.callCount).to.be 4
          done()

    it 'should allow events to be passed as a function', ->
      class E extends TestView
        events: ->
          'click': 'handler'
        handler: sinon.spy()

      e = new E
      window.clickOnElement e.el
      expect(e.handler).was.calledOnce()
      expect(e.handler).was.calledOn(e)

    it 'should allow "listen" to be passed as a function', ->
      class E extends TestView
        listen: ->
          'test': 'handler'
        handler: sinon.spy()

      e = new E
      e.trigger 'test'
      expect(e.handler).was.calledOnce()
      expect(e.handler).was.calledOn(e)

    it 'should add and return subviews', ->
      expect(view.subview).to.be.a 'function'

      subview = new View()
      view.subview 'fooSubview', subview
      expect(view.subview 'fooSubview').to.be subview
      expect(view.subviews.length).to.be 1

      subview2 = new View()
      view.subview 'fooSubview', subview2
      expect(view.subview 'fooSubview').to.be subview2
      expect(view.subviews.length).to.be 1

    it 'should remove subviews', ->
      expect(view.removeSubview).to.be.a 'function'

      # By name
      subview = new View()
      view.subview 'fooSubview', subview

      view.removeSubview 'fooSubview'
      expect(typeof view.subview('fooSubview')).to.be 'undefined'
      expect(view.subviews.length).to.be 0

      # By view
      subview = new View()
      view.subview 'barSubview', subview

      view.removeSubview subview
      expect(typeof view.subview('barSubview')).to.be 'undefined'
      expect(view.subviews.length).to.be 0

      # Fail silently.
      view.removeSubview ''
      expect(view.subviews.length).to.be 0

    it 'should return empty template data without a model', ->
      templateData = view.getTemplateData()
      expect(templateData).to.be.an 'object'
      isEmpty = (Object.keys or _.keys)(templateData).length is 0
      expect(isEmpty).to.be true

    it 'should return proper template data for a Chaplin model', ->
      setModel()
      templateData = view.getTemplateData()
      expect(templateData).to.be.an 'object'
      expect(templateData.foo).to.be 'foo'
      expect(templateData.bar).to.be 'bar'

    it 'should return template data that protects the model', ->
      setModel()
      templateData = view.getTemplateData()
      templateData.qux = 'qux'
      expect(model.get('qux')).to.be undefined

    it 'should return proper template data for a Backbone model', ->
      model = new Backbone.Model foo: 'foo', bar: 'bar'
      view.model = model
      templateData = view.getTemplateData()
      expect(templateData).to.be.an 'object'
      expect(templateData.foo).to.be 'foo'
      expect(templateData.bar).to.be 'bar'

    it 'should return proper template data for Chaplin collections', ->
      model1 = new Model foo: 'foo'
      model2 = new Model bar: 'bar'
      collection = new Collection [model1, model2]
      view.collection = collection

      data = view.getTemplateData()
      expect(data).to.be.an 'object'
      expect(data).to.only.have.keys('items', 'length')
      expect(data.length).to.be 2
      items = data.items
      expect(items).to.be.an 'array'
      expect(data.length).to.be items.length
      expect(items[0]).to.be.an 'object'
      expect(items[0].foo).to.be 'foo'
      expect(items[1]).to.be.an 'object'
      expect(items[1].bar).to.be 'bar'

    it 'should return proper template data for Backbone collections', ->
      model1 = new Backbone.Model foo: 'foo'
      model2 = new Backbone.Model bar: 'bar'
      collection = new Backbone.Collection [model1, model2]
      view.collection = collection

      data = view.getTemplateData()
      expect(data).to.be.an 'object'
      expect(data).to.only.have.keys('items', 'length')
      expect(data.length).to.be 2
      items = data.items
      expect(items).to.be.an 'array'
      expect(items.length).to.be 2
      expect(items[0]).to.be.an 'object'
      expect(items[0].foo).to.be 'foo'
      expect(items[1]).to.be.an 'object'
      expect(items[1].bar).to.be 'bar'

    it 'should add the SyncMachine state to the template data', ->
      setModel()
      _.extend model, SyncMachine
      templateData = view.getTemplateData()
      expect(templateData.synced).to.be false
      model.beginSync()
      model.finishSync()
      templateData = view.getTemplateData()
      expect(templateData.synced).to.be true

    it 'should not cover existing SyncMachine properties', ->
      setModel()
      _.extend model, SyncMachine
      model.set syncState: 'foo', synced: 'bar'
      templateData = view.getTemplateData()
      expect(templateData.syncState).to.be 'foo'
      expect(templateData.synced).to.be 'bar'

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
        view = new EventedView model: new Model()

        expect(view.a1Handler).was.notCalled()
        expect(view.a2Handler).was.notCalled()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        view.trigger 'ns:a'
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        view.trigger 'ns:b'
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.calledOnce()
        expect(view.b2Handler).was.calledOnce()

      it 'should bind to model events declaratively', ->
        model = new Model()
        view = new EventedView {model}

        expect(view.a1Handler).was.notCalled()
        expect(view.a2Handler).was.notCalled()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        model.set 'a', 1
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        model.set 'b', 2
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.calledOnce()
        expect(view.b2Handler).was.calledOnce()

      it 'should bind to collection events declaratively', ->
        collection = new Collection()
        view = new EventedView {collection}

        expect(view.a1Handler).was.notCalled()
        expect(view.a2Handler).was.notCalled()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        collection.reset [{a: 1}]
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        collection.trigger 'custom'
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.calledOnce()
        expect(view.b2Handler).was.calledOnce()

      it 'should bind to mediator events declaratively', ->
        view = new EventedView()

        expect(view.a1Handler).was.notCalled()
        expect(view.a2Handler).was.notCalled()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        mediator.publish 'ns:a'
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.notCalled()
        expect(view.b2Handler).was.notCalled()

        mediator.publish 'ns:b'
        expect(view.a1Handler).was.calledOnce()
        expect(view.a2Handler).was.calledOnce()
        expect(view.b1Handler).was.calledOnce()
        expect(view.b2Handler).was.calledOnce()

      it 'should throw an error when corresponding method doesn’t exist', ->
        class ErrorView extends View
          listen:
            'stuff': 'stuff'
        class Error2View extends ConfiguredTestView
          events:
            'stuff': 'stuff'
        expect(-> new ErrorView).to.throwError()
        expect(-> new Error2View).to.throwError()

      it 'should allow passing params to delegateEvents', (done) ->
        spy = sinon.spy()
        view = new AutoRenderView
        view.delegateEvents 'click p': spy
        window.clickOnElement view.el.querySelector('p')
        delay ->
          expect(spy).was.calledOnce()
          done()

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
        view = new PreservedView
        parent = view.el
        el = parent.querySelector('p')
        window.clickOnElement el
        expect(spy1).was.called()
        expect(spy2).was.called()
        view.dispose()
        window.clickOnElement el
        expect(spy1.callCount).to.be 1
        expect(spy2.callCount).to.be 1
        parent.parentNode.removeChild(parent)

      it 'should register event handlers on the document programatically', ->
        spy1 = sinon.spy()
        spy2 = sinon.spy()
        class PreservedView extends TestView
          autoRender: true
          container: 'body'
          keepElement: true
        view = new PreservedView
        view.testClickHandler = spy1
        view.delegateEvents
          'click p': 'testClickHandler'
          click: spy2
        parent = view.el
        el = parent.querySelector('p')
        window.clickOnElement el
        expect(spy1).was.called()
        expect(spy2).was.called()
        view.undelegateEvents()
        window.clickOnElement el
        expect(spy1.callCount).to.be 1
        expect(spy2.callCount).to.be 1
        parent.parentNode.removeChild(parent)

    it 'should pass model attributes to the template function', ->
      setModel()

      sinon.spy(view, 'getTemplateData')

      passedTemplateData = null
      templateFunc = sinon.stub().returns(template)
      sinon.stub(view, 'getTemplateFunction').returns(templateFunc)

      view.render()

      expect(view.getTemplateFunction).was.called()
      expect(view.getTemplateData).was.called()
      expect(templateFunc).was.called()

      templateData = templateFunc.lastCall.args[0]
      expect(templateData).to.be.an 'object'
      expect(templateData.foo).to.be 'foo'
      expect(templateData.bar).to.be 'bar'

    describe 'Disposal', ->

      it 'should dispose itself correctly', ->
        expect(view.dispose).to.be.a 'function'
        view.dispose()

        expect(view.disposed).to.be true
        if Object.isFrozen
          expect(Object.isFrozen(view)).to.be true

      it 'should remove itself from the DOM', ->
        view.el.id = 'disposed-view'
        document.body.appendChild view.el
        expect(document.querySelector('#disposed-view')).to.be.true
        view.dispose()
        expect(document.querySelector('#disposed-view')).to.be.false

      it 'should call Backbone.View#remove', ->
        sinon.spy view, 'remove'
        view.dispose()
        expect(view.remove).was.called()

      it 'should dispose subviews', ->
        subview = new View()
        sinon.spy(subview, 'dispose')
        view.subview 'foo', subview

        view.dispose()

        expect(subview.disposed).to.be true
        expect(subview.dispose).was.called()

      it 'should unsubscribe from Pub/Sub events', ->
        spy = sinon.spy()
        view.subscribeEvent 'foo', spy

        view.dispose()

        mediator.publish 'foo'
        expect(spy).was.notCalled()

      it 'should unsubscribe from model events', ->
        setModel()
        spy = sinon.spy()
        view.listenTo view.model, 'foo', spy

        view.dispose()

        model.trigger 'foo'
        expect(spy).was.notCalled()

      it 'should remove all event handlers from itself', ->
        spy = sinon.spy()
        view.on 'foo', spy

        view.dispose()

        view.trigger 'foo'
        expect(spy).was.notCalled()

      it 'should remove instance properties', ->
        view.dispose()

        properties = [
          'el', '$el',
          'options', 'model', 'collection',
          'subviews', 'subviewsByName',
          '_callbacks'
        ]
        for prop in properties
          expect(view).not.to.have.own.property prop

      it 'should dispose itself when the model is disposed', ->
        model = new Model()
        view = new TestView {model}
        model.dispose()
        expect(model.disposed).to.be true
        expect(view.disposed).to.be true

      it 'should dispose itself when the collection is disposed', ->
        collection = new Collection()
        view = new TestView {collection}
        collection.dispose()
        expect(collection.disposed).to.be true
        expect(view.disposed).to.be true

      it 'should not dispose itself when the collection model is disposed', ->
        collection = new Collection [{a: 1}, {a: 2}, {a: 3}]
        view = new TestView {collection}
        collection.at(0).dispose()
        expect(collection.disposed).to.be false
        expect(view.disposed).to.be false

      it 'should not render when disposed given render wasn’t overridden', ->
        # Vanilla View which doesn’t override render
        view = new View()
        view.getTemplateFunction = TestView::getTemplateFunction
        sinon.spy(view, 'attach')
        renderResult = view.render()
        expect(renderResult).to.be view

        view.dispose()

        renderResult = view.render()
        expect(renderResult).to.be false
        expect(view.attach.callCount).to.be 1

      it 'should not render when disposed given render was overridden', ->
        initial = testbed.children.length
        view = new TestView container: '#testbed'
        sinon.spy(view, 'attach')
        renderResult = view.render()
        expect(renderResult).to.be renderReturnValue
        expect(view.attach.callCount).to.be 1
        expect(renderCalled).to.be true
        expect(view.el.parentNode).to.be testbed

        view.dispose()

        renderResult = view.render()
        expect(renderResult).to.be false
        # Render was called but super call should not do anything
        expect(renderCalled).to.be true
        expect(testbed.children.length).to.be initial
        expect(view.attach.callCount).to.be 1
