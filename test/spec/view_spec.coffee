define [
  'underscore'
  'jquery'
  'chaplin/mediator'
  'chaplin/views/view'
  'chaplin/models/model'
  'chaplin/models/collection'
  'chaplin/lib/event_broker'
], (_, $, mediator, View, Model, Collection, EventBroker) ->
  'use strict'

  describe 'View', ->
    #console.debug 'View spec'

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
        model.dispose()
        model = null
      if collection
        collection.dispose()
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
      expect(renderCalled).to.not.be.ok()
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

    it 'should register user input events', ->
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

    it 'should check delegate parameters', ->
      expect(-> view.delegate()).to.throwError()
      expect(-> view.delegate(1, 2, 3)).to.throwError()
      expect(-> view.delegate('click', 'foo')).to.throwError()
      expect(-> view.delegate('click', 'foo', 'bar')).to.throwError()
      expect(-> view.delegate('click', 123)).to.throwError()
      expect(-> view.delegate('click', (->), 123)).to.throwError()

    it 'should bind handlers to model events', ->
      expect(view.modelBind).to.be.a 'function'
      expect(-> view.modelBind()).to.throwError()
      expect(-> view.modelBind(1, 2)).to.throwError()
      expect(-> view.modelBind(1, ->)).to.throwError()
      expect(-> view.modelBind('change:foo', ->)).to.throwError()

      setModel()
      spy = sinon.spy()
      view.modelBind 'change:foo', spy
      model.set foo: 'bar'
      expect(spy).was.called()

      view.modelBind 'change:foo', spy
      model.set foo: 'qux'
      expect(spy.callCount).to.be 2

    it 'should bind handlers to collection events', ->
      setCollection()
      spy = sinon.spy()
      view.modelBind 'add', spy
      collection.push new Model()
      expect(spy).was.called()

    it 'should unbind handlers from model events', ->
      expect(view.modelUnbind).to.be.a 'function'

      setModel()
      spy = sinon.spy()
      view.modelBind 'change:foo', spy
      view.modelUnbind 'change:foo', spy
      model.set foo: 'bar'
      expect(spy).was.notCalled()

    it 'should unbind handlers from collection events', ->
      setCollection()
      spy = sinon.spy()
      view.modelBind 'add', spy
      view.modelUnbind 'add', spy
      collection.push new Model()
      expect(spy).was.notCalled()

    it 'should force the context of model event handlers', ->
      setModel()

      context = null
      view.modelBind 'foo', ->
        context = this
      model.trigger 'foo'
      expect(context).to.be view

    bindAndTrigger = (model, view) ->
      fooSpy = sinon.spy()
      view.modelBind 'foo', fooSpy
      barSpy = sinon.spy()
      view.modelBind 'bar', barSpy
      allSpy = sinon.spy()
      view.modelBind 'all', allSpy
      model.trigger 'foo bar'
      expect(fooSpy.callCount).to.be 1
      expect(barSpy.callCount).to.be 1
      expect(allSpy.callCount).to.be 2
      view.modelUnbindAll()
      view.trigger 'foo bar'
      expect(fooSpy.callCount).to.be 1
      expect(barSpy.callCount).to.be 1
      expect(allSpy.callCount).to.be 2

    it 'should unbind all model handlers', ->
      expect(view.modelUnbindAll).to.be.a 'function'
      setModel()
      bindAndTrigger model, view

    it 'should unbind all collection handlers', ->
      setCollection()
      bindAndTrigger collection, view
      collection.dispose()

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

    it 'should return proper template data for a model', ->
      setModel()
      templateData = view.getTemplateData()
      expect(templateData).to.be.an 'object'
      expect(templateData.foo).to.be 'foo'
      expect(templateData.bar).to.be 'bar'

    it 'should return proper template data for collections', ->
      model1 = new Model foo: 'foo'
      model2 = new Model bar: 'bar'
      collection = new Collection [model1, model2]
      view.collection = collection

      d = view.getTemplateData()
      expect(d).to.be.an 'object'
      expect(d.items).to.be.an 'array'
      expect(_.isObject d.items[0]).to.be true
      expect(d.items[0].foo).to.be 'foo'
      expect(_.isObject d.items[1]).to.be true
      expect(d.items[1].bar).to.be 'bar'

    it 'should add the Deferred state to the template data', ->
      setModel()
      model.initDeferred()
      templateData = view.getTemplateData()
      expect(templateData.resolved).to.not.be.ok()
      model.resolve()
      templateData = view.getTemplateData()
      expect(templateData.resolved).to.be true

    it 'should add the SyncMachine state to the template data', ->
      setModel()
      model.initSyncMachine()
      templateData = view.getTemplateData()
      expect(templateData.synced).to.not.be.ok()
      model.beginSync()
      model.finishSync()
      templateData = view.getTemplateData()
      expect(templateData.synced).to.be true

    it 'should not cover existing synced and resolved properties', ->
      setModel()
      model.initDeferred()
      model.initSyncMachine()
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
      modelBindSpy = sinon.spy()
      view.modelBind 'foo', modelBindSpy

      view.dispose()

      model.trigger 'foo'
      expect(modelBindSpy).was.notCalled()

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
        expect(_(view).has prop).to.not.be.ok()

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
      expect(renderResult).to.not.be.ok()
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
      expect(renderResult).to.not.be.ok()
      # Render was called but super call should not do anything
      expect(renderCalled).to.be true
      expect($(testbed).children().length).to.be 0
      expect(view.afterRender.callCount).to.be 1
