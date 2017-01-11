import Application from './chaplin/application'
import Composer from './chaplin/composer'
import Controller from './chaplin/controllers/controller'
import Dispatcher from './chaplin/dispatcher'
import Composition from './chaplin/lib/composition'
import EventBroker from './chaplin/lib/event_broker'
import History from './chaplin/lib/history'
import Route from './chaplin/lib/route'
import Router from './chaplin/lib/router'
import support from './chaplin/lib/support'
import SyncMachine from './chaplin/lib/sync_machine'
import utils from './chaplin/lib/utils'
import mediator from './chaplin/mediator'
import Collection from './chaplin/models/collection'
import Model from './chaplin/models/model'
import CollectionView from './chaplin/views/collection_view'
import Layout from './chaplin/views/layout'
import View from './chaplin/views/view'

# Main entry point into Chaplin module.
# Load all components and expose them.
export default {
  Application
  Composer
  Controller
  Dispatcher
  Composition
  EventBroker
  History
  Route
  Router
  support
  SyncMachine
  utils
  mediator
  Collection
  Model
  CollectionView
  Layout
  View
}
