
define(['lib/utils', 'lib/subscriber'], function(utils, Subscriber) {
  'use strict';
  var ServiceProvider;
  return ServiceProvider = (function() {

    _(ServiceProvider.prototype).defaults(Subscriber);

    ServiceProvider.prototype.loading = false;

    function ServiceProvider() {
      _(this).extend($.Deferred());
      utils.deferMethods({
        deferred: this,
        methods: ['triggerLogin', 'getLoginStatus'],
        onDeferral: this.loadSDK
      });
    }

    return ServiceProvider;

  })();
  /*
  
      Standard methods and their signatures:
  
      loadSDK: ->
        # Load a script like this:
        utils.loadLib 'http://example.org/foo.js', @sdkLoadHandler, @reject
  
      sdkLoadHandler: =>
        # Init the SDK, then resolve
        someSDK.init(foo: 'bar')
        @resolve()
  
      isLoaded: ->
        # Return a Boolean
        Boolean window.someSDK and someSDK.login
  
      # Trigger login popup
      triggerLogin: (loginContext) ->
        callback = _(@loginHandler).bind(@, @loginHandler)
        someSDK.login callback
  
      # Callback for the login popup
      loginHandler: (loginContext, response) =>
  
        if response
          # Publish successful login
          mediator.publish 'loginSuccessful', provider: @, loginContext: loginContext
  
          # Publish the session
          mediator.publish 'serviceProviderSession',
            provider: @
            userId: response.userId
            accessToken: response.accessToken
            # etc.
  
        else
          mediator.publish 'loginFail', provider: @, loginContext: loginContext
  
      getLoginStatus: (callback = @loginStatusHandler, force = false) ->
        someSDK.getLoginStatus callback, force
  
      loginStatusHandler: (response) =>
        return unless response
        mediator.publish 'serviceProviderSession',
          provider: @
          userId: response.userId
          accessToken: response.accessToken
          # etc.
  */
});
