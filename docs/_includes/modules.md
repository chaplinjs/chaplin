### Core
* [Chaplin.mediator](./chaplin.mediator.html) — global event pub / sub bus.
* [Chaplin.Dispatcher](./chaplin.dispatcher.html) — router <-> controller broker.
* [Chaplin.Layout](./chaplin.layout.html) — top-level application view.
* [Chaplin.Application](./chaplin.application.html) — application boostrapper.

### MVC
* [Chaplin.Controller](./chaplin.controller.html) — a place for initializing models / collections and views.
* [Chaplin.Model](./chaplin.model.html) — extension of `Backbone.Model` that adds disposal (memory clean-up) and better serializer.
* [Chaplin.Collection](./chaplin.collection.html) — extension of `Backbone.Collection` that adds disposal.
* [Chaplin.View](./chaplin.view.html) — extension of `Backbone.View` with better support for templates, regions, subviews and disposal.
* [Chaplin.CollectionView](./chaplin.collection_view.html) — extension of `Chaplin.View` responsible for displaying collections. Creates `Chaplin.View` instance for every collection model.

### Libs
* [Chaplin.EventBroker](./chaplin.event_broker.html) — mediator Pub / Sub mix-in.
* [Chaplin.SyncMachine](./chaplin.sync_machine.html) — finite state machine for models / collections.
* [Chaplin.Router](./chaplin.router.html) — replacement for `Backbone.Router`.
* [Chaplin.Route](./chaplin.route.html) — small abstraction used in `Chaplin.Router`.
* [Chaplin.support](./chaplin.support.html) — feature detection.
* [Chaplin.utils](./chaplin.utils.html) — generic utils.
* [Chaplin.helpers](./chaplin.helpers.html) — Chaplin-specific helpers.
