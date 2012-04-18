define [
  'underscore',
  'lib/utils',
  'chaplin/lib/support'
], (_, utils, chaplinSupport) ->

  # Application-specific feature detection
  # --------------------------------------

  # Delegate to Chaplin’s support module
  support = utils.beget chaplinSupport

  # _(support).extend

    # someMethod: ->

  support
