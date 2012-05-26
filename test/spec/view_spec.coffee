define [
  'jquery'
  'chaplin/mediator'
  'chaplin/views/view'
  'chaplin/models/model'
  'chaplin/models/collection'
  'chaplin/lib/subscriber'
], ($, mediator, View, Model, Collection, Subscriber) ->
  'use strict'

  describe 'View', ->
    #console.debug 'View spec'

    renderCalled = false
    view = model = collection = null
    template = '<p>content</p>'

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

      initialize: ->
        super

      render: ->
        super
        renderCalled = true

    class ConfiguredTestView extends TestView

      autoRender: true
      container: '#jasmine-root'
      containerMethod: 'before'

    it 'should mixin a Subscriber', ->
      for own name, value of Subscriber
        expect(view[name]).toBe Subscriber[name]

    it 'should render automatically', ->
      view = new TestView autoRender: true
      expect(renderCalled).toBe true
      expect(view.el.parentNode).toBe null
      view.dispose()

    it 'should attach itself to an element automatically', ->
      view = new TestView container: document.body
      expect(renderCalled).toBe false
      # Expect that the view is attached to the DOM *on first render*,
      # not immediately after initialize
      expect(view.el.parentNode).toBe null
      view.render()
      expect(view.el.parentNode).toBe document.body
      view.dispose()

    it 'should attach itself to a selector automatically', ->
      view = new TestView container: 'body'
      view.render()
      expect(view.el.parentNode).toBe document.body
      view.dispose()

    it 'should attach itself to a jQuery object automatically', ->
      view = new TestView container: $('body')
      view.render()
      expect(view.el.parentNode).toBe document.body
      view.dispose()

    it 'should use the given attach method', ->
      refEl = document.getElementById 'jasmine-root'
      view = new TestView container: refEl, containerMethod: 'after'
      view.render()
      expect(view.el).toBe refEl.nextSibling
      expect(view.el.parentNode).toBe refEl.parentNode
      view.dispose()

    it 'should consider configuration properties', ->
      refEl = document.getElementById 'jasmine-root'
      view = new ConfiguredTestView
      expect(renderCalled).toBe true
      expect(view.el).toBe refEl.previousSibling
      expect(view.el.parentNode).toBe refEl.parentNode
      view.dispose()

    it 'should register user input events', ->
      expect(typeof view.delegate).toBe 'function'
      expect(typeof view.undelegate).toBe 'function'

      spy = jasmine.createSpy()
      handler = view.delegate 'click', spy
      expect(typeof handler).toBe 'function'
      $(view.el).trigger 'click'
      expect(spy).toHaveBeenCalled()

      view.undelegate()
      $(view.el).trigger 'click'
      expect(spy.callCount).toBe 1

      view.render()
      spy = jasmine.createSpy()
      handler = view.delegate 'click', 'p', spy
      expect(typeof handler).toBe 'function'
      p = view.$('p')
      expect(p.length).toBe 1
      p.trigger 'click'
      expect(spy).toHaveBeenCalled()

      view.undelegate()
      p.trigger 'click'
      expect(spy.callCount).toBe 1

    it 'should check delegate parameters', ->
      expect(-> view.delegate()).toThrow()
      expect(-> view.delegate(1, 2, 3)).toThrow()
      expect(-> view.delegate('click', 'foo')).toThrow()
      expect(-> view.delegate('click', 'foo', 'bar')).toThrow()
      expect(-> view.delegate('click', 123)).toThrow()
      expect(-> view.delegate('click', (->), 123)).toThrow()

    it 'should bind handlers to model events', ->
      expect(typeof view.modelBind).toBe 'function'
      expect(-> view.modelBind()).toThrow()
      expect(-> view.modelBind(1, 2)).toThrow()
      expect(-> view.modelBind(1, ->)).toThrow()
      expect(-> view.modelBind('change:foo', ->)).toThrow()

      setModel()
      spy = jasmine.createSpy()
      view.modelBind 'change:foo', spy
      model.set foo: 'bar'
      expect(spy).toHaveBeenCalled()

      view.modelBind 'change:foo', spy
      model.set foo: 'qux'
      expect(spy.callCount).toBe 2

    it 'should bind handlers to collection events', ->
      setCollection()
      spy = jasmine.createSpy()
      view.modelBind 'add', spy
      collection.push new Model()
      expect(spy).toHaveBeenCalled()

    it 'should unbind handlers from model events', ->
      expect(typeof view.modelUnbind).toBe 'function'

      setModel()
      spy = jasmine.createSpy()
      view.modelBind 'change:foo', spy
      view.modelUnbind 'change:foo', spy
      model.set foo: 'bar'
      expect(spy).not.toHaveBeenCalled()

    it 'should unbind handlers from collection events', ->
      setCollection()
      spy = jasmine.createSpy()
      view.modelBind 'add', spy
      view.modelUnbind 'add', spy
      collection.push new Model()
      expect(spy).not.toHaveBeenCalled()

    it 'should force the context of model event handlers', ->
      setModel()

      context = null
      view.modelBind 'foo', ->
        context = this
      model.trigger 'foo'
      expect(context).toBe view

    bindAndTrigger = (model, view) ->
      fooSpy = jasmine.createSpy()
      view.modelBind 'foo', fooSpy
      barSpy = jasmine.createSpy()
      view.modelBind 'bar', barSpy
      allSpy = jasmine.createSpy()
      view.modelBind 'all', allSpy
      model.trigger 'foo bar'
      expect(fooSpy.callCount).toBe 1
      expect(barSpy.callCount).toBe 1
      expect(allSpy.callCount).toBe 2
      view.modelUnbindAll()
      view.trigger 'foo bar'
      expect(fooSpy.callCount).toBe 1
      expect(barSpy.callCount).toBe 1
      expect(allSpy.callCount).toBe 2

    it 'should unbind all model handlers', ->
      expect(typeof view.modelUnbindAll).toBe 'function'
      setModel()
      bindAndTrigger model, view

    it 'should unbind all collection handlers', ->
      setCollection()
      bindAndTrigger collection, view
      collection.dispose()

    it 'should pass model attributes to elements', ->
      expect(typeof view.pass).toBe 'function'
      setModel()
      view.pass 'foo', 'p'
      view.render()
      p = view.$('p')
      expect(p.text()).toBe 'content'
      model.set foo: 'bar'
      expect(p.text()).toBe 'bar'

    it 'should pass model attributes to input elements', ->
      setModel()
      view.$el.html('<p><input type="text" id="foo"></p>')
      view.pass 'foo', '#foo'
      input = view.$('input')
      expect(input.val()).toBe ''
      model.set foo: 'bar'
      expect(input.val()).toBe 'bar'

    it 'should add and return subviews', ->
      expect(typeof view.subview).toBe 'function'

      subview = new View()
      view.subview 'fooSubview', subview
      expect(view.subview 'fooSubview').toBe subview
      expect(view.subviews.length).toBe 1

      subview2 = new View()
      view.subview 'fooSubview', subview2
      expect(view.subview 'fooSubview').toBe subview2
      expect(view.subviews.length).toBe 1

    it 'should remove subviews', ->
      expect(typeof view.removeSubview).toBe 'function'

      # By name
      subview = new View()
      view.subview 'fooSubview', subview

      view.removeSubview 'fooSubview'
      expect(typeof view.subview('fooSubview')).toBe 'undefined'
      expect(view.subviews.length).toBe 0

      # By view
      subview = new View()
      view.subview 'barSubview', subview

      view.removeSubview subview
      expect(typeof view.subview('barSubview')).toBe 'undefined'
      expect(view.subviews.length).toBe 0

    it 'should render a template', ->
      view.render()
      expect(view.$el.html()).toBe template

    it 'should return empty template data without a model', ->
      templateData = view.getTemplateData()
      expect(typeof templateData).toBe 'object'
      expect(_(templateData).isEmpty()).toBe true

    it 'should return proper template data for a model', ->
      setModel()
      templateData = view.getTemplateData()
      expect(typeof templateData).toBe 'object'
      expect(templateData.foo).toBe 'foo'
      expect(templateData.bar).toBe 'bar'

    it 'should return proper template data for collections', ->
      model1 = new Model foo: 'foo'
      model2 = new Model bar: 'bar'
      collection = new Collection [model1, model2]
      view.collection = collection

      d = view.getTemplateData()
      expect(typeof d).toBe 'object'
      expect(typeof d.items).toBe 'object'
      expect(typeof d.items[0]).toBe 'object'
      expect(d.items[0].foo).toBe 'foo'
      expect(typeof d.items[1]).toBe 'object'
      expect(d.items[1].bar).toBe 'bar'

    it 'should add the Deferred state to the template data', ->
      setModel()
      model.initDeferred()
      templateData = view.getTemplateData()
      expect(templateData.resolved).toBe false
      model.resolve()
      templateData = view.getTemplateData()
      expect(templateData.resolved).toBe true

    it 'should add the SyncMachine state to the template data', ->
      setModel()
      model.initSyncMachine()
      templateData = view.getTemplateData()
      expect(templateData.synced).toBe false
      model.beginSync()
      model.finishSync()
      templateData = view.getTemplateData()
      expect(templateData.synced).toBe true

    it 'should not cover existing synced and resolved properties', ->
      setModel()
      model.initDeferred()
      model.initSyncMachine()
      model.set resolved: 'foo', synced: 'bar'
      templateData = view.getTemplateData()
      expect(templateData.resolved).toBe 'foo'
      expect(templateData.synced).toBe 'bar'

    it 'should pass model attributes to the template function', ->
      setModel()

      spyOn(view, 'getTemplateData').andCallThrough()

      passedTemplateData = null
      templateFunc = jasmine.createSpy().andReturn(template)
      spyOn(view, 'getTemplateFunction').andReturn(templateFunc)

      view.render()

      expect(view.getTemplateFunction).toHaveBeenCalled()
      expect(view.getTemplateData).toHaveBeenCalled()
      expect(templateFunc).toHaveBeenCalled()

      templateData = templateFunc.mostRecentCall.args[0]
      expect(typeof templateData).toBe 'object'
      expect(templateData.foo).toBe 'foo'
      expect(templateData.bar).toBe 'bar'

    it 'should dispose itself correctly', ->
      expect(typeof view.dispose).toBe 'function'
      view.dispose()

      expect(view.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(view)).toBe true

    it 'should remove itself from the DOM', ->
      view.$el
        .attr('id', 'disposed-view')
        .appendTo(document.body)
      expect($('#disposed-view').length).toBe 1

      view.dispose()

      expect($('#disposed-view').length).toBe 0

    it 'should dispose subviews', ->
      subview = new View()
      spyOn(subview, 'dispose').andCallThrough()
      view.subview 'foo', subview

      view.dispose()

      expect(subview.disposed).toBe true
      expect(subview.dispose).toHaveBeenCalled()

    it 'should unsubscribe from Pub/Sub events', ->
      pubSubSpy = jasmine.createSpy()
      view.subscribeEvent 'foo', pubSubSpy

      view.dispose()

      mediator.publish 'foo'
      expect(pubSubSpy).not.toHaveBeenCalled()

    it 'should unsubscribe from model events', ->
      setModel()
      modelBindSpy = jasmine.createSpy()
      view.modelBind 'foo', modelBindSpy

      view.dispose()

      model.trigger 'foo'
      expect(modelBindSpy).not.toHaveBeenCalled()

    it 'should remove all event handlers from itself', ->
      viewBindSpy = jasmine.createSpy()
      view.on 'foo', viewBindSpy

      view.dispose()

      view.trigger 'foo'
      expect(viewBindSpy).not.toHaveBeenCalled()

    it 'should remove instance properties', ->
      view.dispose()

      properties = [
        'el', '$el',
        'options', 'model', 'collection',
        'subviews', 'subviewsByName',
        '_callbacks'
      ]
      for prop in properties
        expect(_(view).has prop).toBe false

    it 'should dispose itself when the model or collection is disposed', ->
      model = new Model()
      view = new TestView model: model
      model.dispose()
      expect(model.disposed).toBe true
      expect(view.disposed).toBe true
