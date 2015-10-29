---
layout: default
title: Chaplin.Layout
module_path: src/chaplin/views/layout.coffee
Chaplin: Layout
---

`Chaplin.Layout` is the top-level application “view”. It doesn't inherit from `Chaplin.View` but borrows some of its functionalities. It is tied to the `document` DOM element and handles app-wide events, such as clicks on application-internal links. Most importantly, when a new controller is activated, `Chaplin.Layout` is responsible for changing the main view to the view of the new controller.

<h2 id="methods">Methods</h2>

<h3 class="module-member" id="initialize">initialize([options={}])</h3>

* **options**:
    * **routeLinks** (default `'a, .go-to'`): the selector of elements you want to apply internal routing to. Set to false to deactivate internal routing. If `false`y, chaplin won’t route links at all.
    * **skipRouting** (default `'.noscript'`): if you want to skip the internal routing in some situation. Can take the following value:
        * selector: check if the activated link matches the selector. The default value is a selector and will prevent routing for any links with class `noscript`.
        * function: check the return value. Return `true` to continue routing, return `false` to stop routing. The path and the elements are passed as parameters. Example: `function(href, el) { return href == 'bla'; }`
        * false: never skip routing
    * **openExternalToBlank** (default `false`): whether or not links to external domains should open in a new window/tab.
    * **scrollTo** (default `[0, 0]`): the coordinates (x, y) you want to scroll to on view replacement. Set to *false* to deactivate it.
    * **titleTemplate** (default `_.template("<%= subtitle %> - <%= title %>")`): a function which returns the document title. Per default, it receives an object with the properties `title` and `subtitle`.


<h3 class="module-member" id="delegateEvents">delegateEvents([events])</h3>

A wrapper for `Backbone.View.delegateEvents`. See Backbone [documentation](http://backbonejs.org/#View-delegateEvents) for more details.


<h3 class="module-member" id="undelegateEvents">undelegateEvents()</h3>

A wrapper for `Backbone.View.undelegateEvents`. See Backbone [documentation](http://backbonejs.org/#View-undelegateEvents) for more details.


<h3 class="module-member" id="hideOldView">hideOldView(controller)</h3>

Hide the active (old) view on the `beforeControllerDispose` event sent by the dispatcher on route change and scroll to the coordinates specified by the initialize `scrollTo` option.


<h3 class="module-member" id="showNewView">showNewView(context)</h3>

Show the new view on the `dispatcher:dispatch` event sent by the dispatcher on route change.


<h3 class="module-member" id="adjustTitle">adjustTitle(context)</h3>

Adjust the title of the page based on the `titleTemplate` option. The `title` variable is the one defined at application level, the `subtitle` the one defined at controller level.

<h3 class="module-member" id="openLink">openLink(event)</h3>

Open the `href` or `data-href` URL of a DOM element. When `openLink` is called it checks if the `href` is valid and runs the `skipRouting` function if set by the user. If the `href` is valid, it checks if it is an external link and depending on the `openExternalToBlank` option, opens it in a new window. Finally, if it is an internal link, it starts routing the URL.

## Usage

### App-wide events

To register app-wide events, you can define them in the `events` hash. It works like `Backbone.View.delegateEvent` on the `document` DOM element.


### Route links internally

If you want to route links internally, you can use the `events` hash with the `openLink` function like so:

```coffeescript
events:
  'click a': 'openLink'
```

```javascript
events: {
  'click a': 'openLink'
}
```

To open all external links (different hostname) in a new window, you can set `openExternalToBlank` to true when initializing `Chaplin.Layout` in your `Application`:

```coffeescript
class MyApplication extends Chaplin.Application
  initialize: ->
    # ...
    @initLayout openExternalToBlank: true
```

```javascript
var MyApplication = Chaplin.Application.extend({
  initialize: function() {
    // ...
    this.initLayout({openExternalToBlank: true});
  }
});
```

To add a custom check whether or not a link should be open internally, you can override the `isExternalLink` method:

```coffeescript
class Layout extends Chaplin.Layout
  isExternalLink: (href) -> # some test on the href variable
```

```javascript
var Layout = Chaplin.Layout.extend({
  isExternalLink: function(href) {} // some test on the href variable
});
```

### View loading

There is nothing to do, the Layout is listening to the `beforeControllerDispose` and `dispatcher:dispatch` and will trigger the function when a new route is called. If you are not happy with the site scrolling to the top of the page on each view load, you can set the `scrollTo` option when initializing `Chaplin.Layout` in your `Application`:

```coffeescript
class MyApplication extends Chaplin.Application

  initialize: ->
    # ...
    @initLayout
      scrollTo: [10, 30] # will scroll to x=10px and y=30px.
      # OR
      scrollTo: false    # deactivate the scroll
```

```javascript
var MyApplication = Chaplin.Application.extend({
  initialize: function() {
    // ...
    this.initLayout({
      scrollTo: [10, 30] // will scroll to x=10px and y=30px.
      // OR
      scrollTo: false    // deactivate the scroll
    });
  }
});
```
