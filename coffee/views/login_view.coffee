define ['mediator', 'lib/utils', 'views/view', 'text!templates/login.hbs'], (mediator, utils, View, template) ->

  'use strict'

  class LoginView extends View

    # This is a workaround. In the end you might want to used precompiled templates.
    @template = template

    id: 'login'

    containerSelector: '#sidebar-container'

    initialize: (options) ->
      super

      @render()
      # Re-render on login/logout
      @subscribeEvent 'loginStatus', @render

      @initButtons options.serviceProviders

    # In this project we currently only have one service provider and therefore
    # one button. But this should allow for different service providers.

    initButtons: (serviceProviders) ->

      for serviceProviderName, serviceProvider of serviceProviders

        buttonSelector = ".#{serviceProviderName}"
        @$(buttonSelector).addClass('service-loading')

        login = _(@loginWith).bind(@, serviceProviderName, serviceProvider)
        @delegate 'click', buttonSelector, login

        loaded = _(@serviceProviderLoaded).bind(@, serviceProviderName, serviceProvider)
        serviceProvider.done loaded

        failed = _(@serviceProviderFailed).bind(@, serviceProviderName, serviceProvider)
        serviceProvider.fail failed

    loginWith: (serviceProviderName, serviceProvider, e) ->
      e.preventDefault()
      return unless serviceProvider.isLoaded()
      mediator.publish 'login:pickService', serviceProviderName
      mediator.publish '!login', serviceProviderName

    serviceProviderLoaded: (serviceProviderName) ->
      #console.debug 'LoginView#serviceProviderLoaded', serviceProviderName
      @$(".#{serviceProviderName}").removeClass('service-loading')

    serviceProviderFailed: (serviceProviderName) ->
      #console.debug 'LoginView#serviceProviderFailed', serviceProviderName
      @$(".#{serviceProviderName}")
        .removeClass('service-loading')
        .addClass('service-unavailable')
        .attr('disabled', true)
        .attr('title', "Error connecting. Please check whether you are blocking #{utils.upcase(serviceProviderName)}.")

    render: ->
      super

      # Append to DOM
      @$container.append @el
