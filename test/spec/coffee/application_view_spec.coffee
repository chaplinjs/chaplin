define [
  'mediator',
  'chaplin/controllers/controller',
  'chaplin/views/application_view',
  'chaplin/views/view'
], (mediator, Controller, ApplicationView, View) ->
  'use strict'

  describe 'ApplicationView', ->
    applicationView = testController = startupControllerContext = undefined

    beforeEach ->
      # Create the application view
      applicationView.dispose() if applicationView
      applicationView = new ApplicationView title: 'Test Site Title'

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

    it 'should hide the view of an inactive controller', ->
      testController.view.$el.css 'display', 'block'
      mediator.publish 'beforeControllerDispose', testController
      expect(testController.view.$el.css('display')).toBe 'none'

    it 'should show the view of the active controller', ->
      testController.view.$el.css 'display', 'none'
      mediator.publish 'startupController', startupControllerContext
      $el = testController.view.$el
      expect($el.css('display')).toBe 'block'
      expect($el.css('opacity')).toBe '1'
      expect($el.css('visibility')).toBe 'visible'

    it 'should hide accessible fallback content', ->
      $(document.body).append(
        '<p class="accessible-fallback" style="display: none">Accessible fallback</p>'
      )
      mediator.publish 'startupController', startupControllerContext
      expect($('.accessible-fallback').length).toBe 0

    it 'should set the document title', ->
      runs ->
        mediator.publish 'startupController', startupControllerContext
      waits 100
      runs ->
        title = "#{testController.title} \u2013 #{applicationView.title}"
        expect(document.title).toBe title

    it 'should set logged-in/logged-out body classes', ->
      $body = $(document.body).attr('class', '')

      mediator.publish 'loginStatus', true
      expect($body.attr('class')).toBe 'logged-in'

      mediator.publish 'loginStatus', false
      expect($body.attr('class')).toBe 'logged-out'

    it 'should route clicks on internal links', ->
      passedPath = passedCallback = undefined
      routerRoute = (path, callback) ->
        passedPath = path
        passedCallback = callback

      mediator.subscribe '!router:route', routerRoute
      path = '/an/internal/link'
      $("<a href='#{path}'>")
        .appendTo(document.body)
        .click()
        .remove()
      expect(passedPath).toBe path
      expect(typeof passedCallback).toBe 'function'
      mediator.unsubscribe '!router:route', routerRoute

      spy = jasmine.createSpy()
      mediator.subscribe '!router:route', spy
      path = 'http://www.example.org/'
      $("<a href='#{path}'>")
        .appendTo(document.body)
        .click()
        .remove()
      expect(spy).not.toHaveBeenCalled()
      mediator.unsubscribe '!router:route', spy

    it 'should be disposable', ->
      expect(typeof applicationView.dispose).toBe 'function'
      applicationView.dispose()

      expect(applicationView.disposed).toBe true
      if Object.isFrozen
        expect(Object.isFrozen(applicationView)).toBe true