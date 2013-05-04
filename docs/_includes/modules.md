### Core
* [Chaplin.mediator](./chaplin.mediator.md) — global event pub / sub bus.
* [Chaplin.Dispatcher](./chaplin.dispatcher.md) — router <-> controller broker.
* [Chaplin.Layout](./chaplin.layout.md) — top-level application view.
* [Chaplin.Application](./chaplin.application.md) — application boostrapper.

### MVC
* [Chaplin.Controller](./chaplin.controller.md) — a place for initializing models / collections and views.
* [Chaplin.Model](./chaplin.model.md) — extension of `Backbone.Model` that adds disposal (memory clean-up) and better serializer.
* [Chaplin.Collection](./chaplin.collection.md) — extension of `Backbone.Collection` that adds disposal.
* [Chaplin.View](./chaplin.view.md) — extension of `Backbone.View` with better support for templates, regions, subviews and disposal.
* [Chaplin.CollectionView](./chaplin.collection_view.md) — extension of `Chaplin.View` responsible for displaying collections. Creates `Chaplin.View` instance for every collection model.

### Libs
* [Chaplin.EventBroker](./chaplin.event_broker.md) — mediator Pub / Sub mix-in.
* [Chaplin.SyncMachine](./chaplin.sync_machine.md) — finite state machine for models / collections.
* [Chaplin.Router](./chaplin.router.md) — replacement for `Backbone.Router`.
* [Chaplin.Route](./chaplin.route.md) — small abstraction used in `Chaplin.Router`.
* [Chaplin.support](./chaplin.support.md) — feature detection.
* [Chaplin.utils](./chaplin.utils.md) — generic utils.
* [Chaplin.helpers](./chaplin.helpers.md) — Chaplin-specific helpers.
