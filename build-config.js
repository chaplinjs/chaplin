({
  baseUrl: './js/',
  name: "chaplin/application",
  out: "build/chaplin.js",
  include: [
    "chaplin/application",
    "chaplin/lib/create_mediator",
    "chaplin/lib/route",
    "chaplin/lib/router",
    "chaplin/lib/subscriber",
    "chaplin/lib/sync_machine",
    "chaplin/lib/utils",
    "chaplin/controllers/application_controller",
    "chaplin/controllers/controller",
    "chaplin/models/collection",
    "chaplin/models/model",
    "chaplin/views/application_view",
    "chaplin/views/collection_view",
    "chaplin/views/view"
  ],
  paths: {
    text: 'vendor/require-text-1.0.6',
    jquery: 'empty:',
    underscore: 'empty:',
    backbone: 'empty:'
  }
})