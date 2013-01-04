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

    class ConfiguredTestView extends TestView

      autoRender: true
      container: '#testbed'
      containerMethod: 'before'

    it 'should thrown an error if initialize super not called', ->
      class NoInitView extends TestView
        initialize: ->
      view = new NoInitView
      expect(view.dispose).to.throwError()
      view.disposed = true

    it 'should mixin a EventBroker', ->
      for own name, value of EventBroker
        expect(view[name]).to.be EventBroker[name]

    it 'should render', ->
      expect(view.render).to.be.a 'function'
      renderResult = view.render()
      expect(renderResult).to.be view

    it 'should render a template', ->
      view.render()
      innerHTML = view.$el.html().toLowerCase()
      lowerCaseTemplate = template.toLowerCase()
      expect(innerHTML).to.be lowerCaseTemplate

    it 'should render automatically', ->
      view = new TestView autoRender: true
      expect(renderCalled).to.be true
      # should not be in the DOM
      expect(view.$el.parent().length).to.be 0

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
      view = new TestView container: $('#testbed')
      view.render()
      expect(view.el.parentNode).to.be testbed

    it 'should use the given attach method', ->
      view = new TestView container: testbed, containerMethod: 'after'
      view.render()
      expect(view.el).to.be testbed.nextSibling
      expect(view.el.parentNode).to.be testbed.parentNode

    it 'should consider autoRender, container and containerMethod properties', ->
      view = new ConfiguredTestView()
      expect(renderCalled).to.be true
      expect(view.el).to.be testbed.previousSibling
      expect(view.el.parentNode).to.be testbed.parentNode

    it 'should fire an addedToDOM event attching itself to the DOM', ->
      view = new TestView container: testbed
      spy = sinon.spy()
      view.on 'addedToDOM', spy
      view.render()
      expect(spy).was.called()

    it 'should register and remove user input event handlers', ->
      expect(view.delegate).to.be.a 'function'
      expect(view.undelegate).to.be.a 'function'

      spy = sinon.spy()
      handler = view.delegate 'click', spy
      expect(handler).to.be.a 'function'
      $(view.el).trigger 'click'
      expect(spy).was.called()

      view.undelegate()
      $(view.el).trigger 'click'
      expect(spy.callCount).to.be 1

      view.render()
      spy = sinon.spy()
      handler = view.delegate 'click', 'p', spy
      expect(handler).to.be.a 'function'
      p = view.$('p')
      expect(p.length).to.be 1
      p.trigger 'click'
      expect(spy).was.called()

      view.undelegate()
      p.trigger 'click'
      expect(spy.callCount).to.be 1

    it 'should register and remove multiple user input event handlers', ->
      spy = sinon.spy()
      handler = view.delegate 'click keypress', spy
      $(view.el).trigger 'click'
      $(view.el).trigger 'keypress'
      expect(spy).was.calledTwice()

      view.undelegate()
      $(view.el).trigger 'click'
      $(view.el).trigger 'keypress'
      expect(spy).was.calledTwice()

    it 'should check delegate parameters', ->
      expect(-> view.delegate()).to.throwError()
      expect(-> view.delegate(1, 2, 3)).to.throwError()
      expect(-> view.delegate('click', 'foo')).to.throwError()
      expect(-> view.delegate('click', 'foo', 'bar')).to.throwError()
      expect(-> view.delegate('click', 123)).to.throwError()
      expect(-> view.delegate('click', (->), 123)).to.throwError()

    it 'should correct inheritance of events object', (done) ->
      delay = (callback) ->
        window.setTimeout callback, 40
      class A extends TestView
        autoRender: yes
        getTemplateFunction: -> -> '
        <div id="a"></div>
        <div id="b"></div>
        <div id="c"></div>
        <div id="d"></div>'
        events:
          'click #a': 'a1Handler'
        a1Handler: sinon.spy()

        click: (index) ->
          @$("##{index}").click()

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
        a4Handler: sinon.spy()
        dHandler: sinon.spy()

      bcd = ['b', 'c', 'd']
      d = new D
      d.click('a')

      delay ->
        for index in _.range(1, 5)
          expect(d["a#{index}Handler"]).was.calledOnce()
        for index in bcd
          expect(d["#{index}Handler"]).was.notCalled()
          d.click(index)
        delay ->
          for index in bcd
            expect(d["#{index}Handler"]).was.calledOnce()
          done()

    it 'should pass model attributes to elements', ->
      expect(view.pass).to.be.a 'function'
      setModel()
      view.pass 'foo', 'p'
      view.render()
      p = view.$('p')
      expect(p.text()).to.be 'content'
      model.set foo: 'bar'
      expect(p.text()).to.be 'bar'

    it 'should pass model attributes to input elements', ->
      setModel()
      view.$el.html('<p><input type="text" id="foo"></p>')
      view.pass 'foo', '#foo'
      input = view.$('input')
      expect(input.val()).to.be ''
      model.set foo: 'bar'
      expect(input.val()).to.be 'bar'

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

    it 'should return empty template data without a model', ->
      templateData = view.getTemplateData()
      expect(templateData).to.be.an 'object'
      expect(_.isEmpty templateData).to.be true

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

      d = view.getTemplateData()
      expect(d).to.be.an 'object'
      expect(d).to.only.have.keys('items');
      items = d.items
      expect(items).to.be.an 'array'
      expect(items.length).to.be 2
      expect(items[0]).to.be.an 'object'
      expect(items[0].foo).to.be 'foo'
      expect(items[1]).to.be.an 'object'
      expect(items[1].bar).to.be 'bar'

    it 'should return proper template data for Backbone collections', ->
      model1 = new Backbone.Model foo: 'foo'
      model2 = new Backbone.Model bar: 'bar'
      collection = new Backbone.Collection [model1, model2]
      view.collection = collection

      d = view.getTemplateData()
      expect(d).to.be.an 'object'
      expect(d).to.only.have.keys('items');
      items = d.items
      expect(items).to.be.an 'array'
      expect(items.length).to.be 2
      expect(items[0]).to.be.an 'object'
      expect(items[0].foo).to.be 'foo'
      expect(items[1]).to.be.an 'object'
      expect(items[1].bar).to.be 'bar'

    it 'should add the Deferred state to the template data', ->
      setModel()
      model.initDeferred()
      templateData = view.getTemplateData()
      expect(templateData.resolved).to.be false
      model.resolve()
      templateData = view.getTemplateData()
      expect(templateData.resolved).to.be true

    it 'should add the SyncMachine state to the template data', ->
      setModel()
      _.extend model, SyncMachine
      templateData = view.getTemplateData()
      expect(templateData.synced).to.be false
      model.beginSync()
      model.finishSync()
      templateData = view.getTemplateData()
      expect(templateData.synced).to.be true

    it 'should not cover existing synced and resolved properties', ->
      setModel()
      model.initDeferred()
      _.extend model, SyncMachine
      model.set resolved: 'foo', synced: 'bar'
      templateData = view.getTemplateData()
      expect(templateData.resolved).to.be 'foo'
      expect(templateData.synced).to.be 'bar'

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

    it 'should dispose itself correctly', ->
      expect(view.dispose).to.be.a 'function'
      view.dispose()

      expect(view.disposed).to.be true
      if Object.isFrozen
        expect(Object.isFrozen(view)).to.be true

    it 'should remove itself from the DOM', ->
      view.$el
        .attr('id', 'disposed-view')
        .appendTo(document.body)
      expect($('#disposed-view').length).to.be 1

      view.dispose()

      expect($('#disposed-view').length).to.be 0

    it 'should dispose subviews', ->
      subview = new View()
      sinon.spy(subview, 'dispose')
      view.subview 'foo', subview

      view.dispose()

      expect(subview.disposed).to.be true
      expect(subview.dispose).was.called()

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = sinon.spy()
      view.subscribeEvent 'foo', pubSubSpy

      view.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).was.notCalled()

    it 'should unsubscribe from model events', ->
      setModel()
      spy = sinon.spy()
      view.listenTo view.model, 'foo', spy

      view.dispose()

      model.trigger 'foo'
      expect(spy).was.notCalled()

    it 'should remove all event handlers from itself', ->
      viewBindSpy = sinon.spy()
      view.on 'foo', viewBindSpy

      view.dispose()

      view.trigger 'foo'
      expect(viewBindSpy).was.notCalled()

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

    it 'should dispose itself when the model or collection is disposed', ->
      model = new Model()
      view = new TestView model: model
      model.dispose()
      expect(model.disposed).to.be true
      expect(view.disposed).to.be true

    it 'should not render when disposed given render wasn’t overridden', ->
      # Vanilla View which doesn’t override render
      view = new View()
      view.getTemplateFunction = TestView::getTemplateFunction
      sinon.spy(view, 'afterRender')
      renderResult = view.render()
      expect(renderResult).to.be view

      view.dispose()

      renderResult = view.render()
      expect(renderResult).to.be false
      expect(view.afterRender.callCount).to.be 1

    it 'should not render when disposed given render was overridden', ->
      view = new TestView container: '#testbed'
      sinon.spy(view, 'afterRender')
      renderResult = view.render()
      expect(renderResult).to.be view
      expect(view.afterRender.callCount).to.be 1
      expect(renderCalled).to.be true
      expect(view.el.parentNode).to.be testbed

      view.dispose()

      renderResult = view.render()
      expect(renderResult).to.be false
      # Render was called but super call should not do anything
      expect(renderCalled).to.be true
      expect($(testbed).children().length).to.be 0
      expect(view.afterRender.callCount).to.be 1
