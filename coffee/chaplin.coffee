define [
  'chaplin/application',
  'chaplin/dispatcher',
  'chaplin/controllers/controller',
  'chaplin/models/collection',
  'chaplin/models/model',
  'chaplin/views/layout',
  'chaplin/views/view',
  'chaplin/views/collection_view',
  'chaplin/lib/create_mediator',
  'chaplin/lib/route',
  'chaplin/lib/router',
  'chaplin/lib/subscriber',
  'chaplin/lib/support',
  'chaplin/lib/sync_machine',
  'chaplin/lib/utils'
], (mediator, Dispatcher, Controller, Collection, Model, Layout, View, CollectionView, CreateMediator, Route, Router, Subscriber, Support, SyncMachine, Utils) ->
  'use strict'

  return {} =
    Application    : Application
    Dispatcher     : Dispatcher
    Controller     : Controller
    Collection     : Collection
    Model          : Model
    Layout         : Layout
    View           : View
    CollectionView : CollectionView
    CreateMediator : CreateMediator
    Route          : Route
    Router         : Router
    Subscriber     : Subscriber
    Support        : Support
    SyncMachine    : SyncMachine
    Utils          : Utils

