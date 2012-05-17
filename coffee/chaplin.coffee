define [
  'chaplin/application'
  'chaplin/mediator'
  'chaplin/dispatcher'
  'chaplin/controllers/controller'
  'chaplin/models/collection'
  'chaplin/models/model'
  'chaplin/views/layout'
  'chaplin/views/view'
  'chaplin/views/collection_view'
  'chaplin/lib/route'
  'chaplin/lib/router'
  'chaplin/lib/subscriber'
  'chaplin/lib/support'
  'chaplin/lib/sync_machine'
  'chaplin/lib/utils'
], (Application, mediator, Dispatcher, Controller, Collection, Model, Layout, View, CollectionView, Route, Router, Subscriber, support, SyncMachine, utils) ->
  Application    : Application
  mediator       : mediator
  Dispatcher     : Dispatcher
  Controller     : Controller
  Collection     : Collection
  Model          : Model
  Layout         : Layout
  View           : View
  CollectionView : CollectionView
  Route          : Route
  Router         : Router
  Subscriber     : Subscriber
  support        : support
  SyncMachine    : SyncMachine
  utils          : utils
