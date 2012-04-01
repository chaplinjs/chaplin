
define(['lib/utils', 'lib/subscriber'], function(utils, Subscriber) {
  'use strict';
  var ServiceProvider;
  return ServiceProvider = (function() {

    _(ServiceProvider.prototype).extend(Subscriber);

    ServiceProvider.prototype.loading = false;

    function ServiceProvider() {
      _(this).extend($.Deferred());
      utils.deferMethods({
        deferred: this,
        methods: ['triggerLogin', 'getLoginStatus'],
        onDeferral: this.load
      });
    }

    return ServiceProvider;

  })();
  /*
  
      Standard methods and their signatures:
  
      load: ->
        # Load a script like this:
        utils.loadLib 'http://example.org/foo.js', @loadHandler, @reject
  
      loadHandler: =>
        # Init the library, then resolve
        ServiceProviderLibrary.init(foo: 'bar')
        @resolve()
  
      isLoaded: ->
        # Return a Boolean
        Boolean window.ServiceProviderLibrary and ServiceProviderLibrary.login
  
      # Trigger login popup
      triggerLogin: (loginContext) ->
        callback = _(@loginHandler).bind(this, loginContext)
        ServiceProviderLibrary.login callback
  
      # Callback for the login popup
      loginHandler: (loginContext, response) =>
  
        if response
          # Publish successful login
          mediator.publish 'loginSuccessful', {provider: this, loginContext}
  
          # Publish the session
          mediator.publish 'serviceProviderSession',
            provider: this
            userId: response.userId
            accessToken: response.accessToken
            # etc.
  
        else
          mediator.publish 'loginFail', {provider: this, loginContext}
  
      getLoginStatus: (callback = @loginStatusHandler, force = false) ->
        ServiceProviderLibrary.getLoginStatus callback, force
  
      loginStatusHandler: (response) =>
        return unless response
        mediator.publish 'serviceProviderSession',
          provider: this
          userId: response.userId
          accessToken: response.accessToken
          # etc.
  */
});
