define [
  'jquery'
  'chaplin/views/view'
], ($, View) ->
  'use strict'

  describe 'View', ->
    #console.debug 'View spec'

    renderCalled = false

    beforeEach ->
      renderCalled = false

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
      spy = jasmine.createSpy()
      view = new TestView
      expect(typeof view.delegate).toBe 'function'
      view.delegate 'click', spy
      $(view.el).trigger 'click'
      expect(spy).toHaveBeenCalled()
      view.dispose()

    it 'should be tested more properly', ->

