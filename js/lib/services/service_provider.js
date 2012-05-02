
define(['underscore', 'lib/utils', 'chaplin/lib/subscriber'], function(_, utils, Subscriber) {
  'use strict';
  var ServiceProvider;
  return ServiceProvider = (function() {

    _(ServiceProvider.prototype).extend(Subscriber);

    ServiceProvider.prototype.loading = false;

    function ServiceProvider() {
      /*console.debug 'ServiceProvider#constructor'
      */      _(this).extend($.Deferred());
      utils.deferMethods({
        deferred: this,
        methods: ['triggerLogin', 'getLoginStatus'],
        onDeferral: this.load
      });
    }

    ServiceProvider.prototype.disposed = false;

    ServiceProvider.prototype.dispose = function() {
      /*console.debug 'ServiceProvider#dispose'
      */      if (this.disposed) return;
      this.unsubscribeAllEvents();
      this.disposed = true;
      return typeof Object.freeze === "function" ? Object.freeze(this) : void 0;
    };

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
  
        eventPayload = {provider: this, loginContext}
        if response
          # Publish successful login
          mediator.publish 'loginSuccessful', eventPayload
  
          # Publish the session
          mediator.publish 'serviceProviderSession',
            provider: this
            userId: response.userId
            accessToken: response.accessToken
            # etc.
  
        else
          mediator.publish 'loginFail', eventPayload
  
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
