'use strict'

# Main entry point into Chaplin module.
# Load all components and expose them.
module.exports =
  Application:    require './chaplin/application'
  Composer:       require './chaplin/composer'
  Controller:     require './chaplin/controllers/controller'
  Dispatcher:     require './chaplin/dispatcher'
  Composition:    require './chaplin/lib/composition'
  EventBroker:    require './chaplin/lib/event_broker'
  History:        require './chaplin/lib/history'
  Route:          require './chaplin/lib/route'
  Router:         require './chaplin/lib/router'
  support:        require './chaplin/lib/support'
  SyncMachine:    require './chaplin/lib/sync_machine'
  utils:          require './chaplin/lib/utils'
  mediator:       require './chaplin/mediator'
  Collection:     require './chaplin/models/collection'
  Model:          require './chaplin/models/model'
  CollectionView: require './chaplin/views/collection_view'
  Layout:         require './chaplin/views/layout'
  View:           require './chaplin/views/view'
