---
layout: default
title: Chaplin.Composer
module_path: src/chaplin/composer.coffee
Chaplin: Composer
---

## Overview

Grants the ability for views (and related data) to be persisted beyond one controller action.

If a view is reused in a controller action method it will be instantiated and rendered if the view has not been reused in the current or previous action methods.

If a view was reused in the previous action method and is not reused in the current action method, it will be disposed and removed from the DOM.

## Example

A common use case is a login page. This login page is a simple centered form.  However, the main application needs both header and footer controllers.

The following is a sketch of this use case put into code:

```coffeescript
# routes.coffee
(match) ->
  match 'login', 'login#show'
  match '', 'index#show'
  match 'about', 'about#show'


# controllers/login_controller.coffee
Login = require 'views/login'
class LoginController extends Chaplin.Controller
  show: ->
    # Simple view, just want to show the login screen
    @view = new Login()


# controllers/site_controller.coffee
Site = require 'views/site'
Header = require 'views/header'
Footer = require 'views/footer'
class SiteController extends Chaplin.Controller
  beforeAction: ->
    # Reuse the Site view, which is a simple 3-row stacked layout that
    # provides the header, footer, and body regions
    @reuse 'site', Site

    # Reuse the Header view, which binds itself to whatever container
    # is exposed in Site under the header region
    @reuse 'header', Header, region: 'header'

    # Likewise for the footer region
    @reuse 'footer', Footer, region: 'footer'


# controllers/index_controller.coffee
Index = require 'views/index'
SiteController = require 'controllers/site_controller'
class IndexController extends SiteController
  show: ->
    # Instantiate this simple index view at the body region
    @view = new Index region: 'body'


# controllers/about_me_controller.coffee
AboutMe = require 'views/aboutme'
SiteController = require 'controllers/site_controller'
class AboutMeController extends SiteController
  show: ->
    # Instantiate this simple about me view at the body region
    @view = new AboutMe region: 'body'
```

```javascript
// routes.js
function(match) {
  match('login', 'login#show');
  match('', 'index#show');
  match('about', 'about#show');
}

// controllers/login_controller.js
var Login = require('views/login');
var LoginController = Chaplin.Controller.extend({
  show: function() {
    // Simple view, just want to show the login screen.
    this.view = new Login();
  }
});

// controllers/site_controller.js
var Site = require('views/site');
var Header = require('views/header');
var Footer = require('views/footer');
var SiteController = Chaplin.Controller.extend({
  beforeAction: function() {
    // Reuse the Site view, which is a simple 3-row stacked layout that
    // provides the header, footer, and body regions
    this.reuse('site', Site);

    // Reuse the Header view, which binds itself to whatever container
    // is exposed in Site under the header region
    this.reuse('header', Header, {region: 'header'});

    // Likewise for the footer region
    this.reuse('footer', Footer, {region: 'footer'});
  }
});

// controllers/index_controller.js
var Index = require('views/index');
var SiteController = require('controllers/site_controller');
var IndexController = SiteController.extend({
  show: function() {
    // Instantiate this simple index view at the body region.
    this.view = new Index({region: 'body'});
  }
});

// controllers/about_me_controller.js
var AboutMe = require('views/aboutme');
var SiteController = require('controllers/site_controller');
var AboutMeController = SiteController.extend({
  show: function() {
    // Instantiate this simple about me view at the body region.
    this.view = new AboutMe({region: 'body'});
  }
});
```

Given the controllers above here is what would happen each time the URL is routed:

```coffeescript
route('login')
# 'views/login' is initialized and rendered

route('')
# 'views/site' is initialized and rendered
# 'views/header' is initialized and rendered
# 'views/footer' is initialized and rendered
# 'views/index' is initialized and rendered
# 'views/login' is disposed

route('about')
# 'views/aboutme' is initialized and rendered
# 'views/index' is disposed

route('login')
# 'views/login' is initialized and rendered
# 'views/index' is disposed
# 'views/footer' is disposed
# 'views/header' is disposed
# 'views/site' is disposed
```


## Long form

By default, when a controller requests a view to be reused, the composer checks if the view instance exists and the new options are the same as before. If that is true the view is destroyed and reused.

The following example shows another way to use the `compose` method to allow for just about anything. The check method should return true when it wishes the composition to be disposed and the `compose` method to be called. The composer will track and ensure proper disposal of whatever is returned from the compose method (be it a view or an object with properties that have dispose methods).

```coffeescript
  @reuse 'main-post',
    compose: ->
      @model = new Post {id: 42}
      @view = new PostView {@model}
      @model.fetch()

    check: -> @model.id isnt 42
```

```javascript
  this.reuse('main-post', {
    compose: function() {
      this.model = new Post({id: 42});
      this.view = new PostView({model: this.model});
      this.model.fetch();
    },

    check: function() {return this.model.id !== 42;}
  });
```
