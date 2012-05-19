define [
  'jquery'
  'chaplin/views/view'
  'chaplin/models/model'
  'chaplin/models/collection'
], ($, View, Model, Collection) ->
  'use strict'

  describe 'View', ->
    #console.debug 'View spec'

    renderCalled = false
    view = model = collection = null

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
      model = new Model
      view.model = model

    setCollection = ->
      collection = new Collection
      view.collection = collection

    class TestView extends View

      id: 'test-view'

      getTemplateFunction: ->
        -> '<p>content</p>'

      initialize: ->
        super

      render: ->
        super
        renderCalled = true

    class ConfiguredTestView extends TestView

      autoRender: true
      container: '#jasmine-root'
      containerMethod: 'before'

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
      collection.push new Model
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
      collection.push new Model
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

    it 'should add an return subviews', ->
      expect(typeof view.subview).toBe 'function'

      subview = new View
      view.subview 'fooSubview', subview
      expect(view.subview 'fooSubview').toBe subview
      expect(view.subviews.length).toBe 1

      subview2 = new View
      view.subview 'fooSubview', subview2
      expect(view.subview 'fooSubview').toBe subview2
      expect(view.subviews.length).toBe 1

    it 'should remove subviews', ->
      subview = new View
      view.subview 'fooSubview', subview
      expect(typeof view.removeSubview).toBe 'function'
      view.removeSubview 'fooSubview'
      expect(typeof view.subview('fooSubview')).toBe 'undefined'

    it 'should render a template', ->

    it 'should pass serialized attributes to the templating function', ->

    it 'should dispose itself correctly', ->
      view.dispose()
      expect(view.disposed).toBe true

      # To test:
      # Dispose subviews
      # Unbind handlers of global events
      # Unbind all model handlers
      # Remove all event handlers on this module
      # Remove the topmost element from DOM
      # Remove element references, options, model/collection references and subview lists
      # Freezing

    it 'should dispose itself when the model or collection is disposed', ->
      model = new Model
      view = new TestView model: model
      spyOn view, 'dispose'
      model.dispose()
      expect(model.disposed).toBe true
      expect(view.disposed).toBe true
