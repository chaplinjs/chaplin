define [
  'underscore',
  'lib/utils',
  'chaplin/lib/support'
], (_, utils, chaplinSupport) ->

  # Application-specific feature detection
  # --------------------------------------

  # Delegate to Chaplin’s support module
  support = utils.beget chaplinSupport

  # Add additional application-specific properties and methods

  # _(support).extend
    # someProperty: 'foo'
    # someMethod: ->

  support
