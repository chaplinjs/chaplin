# [Chaplin.Composer](src/chaplin/composer.coffee)

## Overview

Grants the ability for views (and related data) to be persisted beyond one
controller action.

If a view is composed in a controller action method it will be instantiated
and rendered if the view has not been composed in the current or previous
action methods.

If a view was composed in the previous action method and is not composed
in the current action method, it will be disposed and removed from the DOM.

## Example

A common use case is a login page. This login page is a simple centered form.
However, the main application needs both header and footer controllers.

Here is this use case demonstrated in coffeescript pseudocode:

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
  before:
    '.*': ->
      # Compose the Site view, which is a simple 3-row stacked layout that
      # provides the header, footer, and body regions
      @compose 'site', Site

      # Compose the Header view, which binds itself to whatever container
      # is exposed in Site under the header region
      @compose 'header', Header, region: 'header'

      # Likewise for the footer region
      @compose 'footer', Footer, region: 'footer'


# controllers/index_controller.coffee
Index = require 'views/index'
SiteController = require 'controllers/site_controller'
class IndexController extends SiteController
  show: ->
      # Instantiate this simple index view at the body region
      @view = new Index, region: 'body'


# controllers/about_me_controller.coffee
AboutMe = require 'views/aboutme'
SiteController = require 'controllers/site_controller'
class AboutMeController extends SiteController
  show: ->
      # Instantiate this simple about me view at the body region
      @view = new AboutMe, region: 'body'
```

Given the controllers above here is what would happen each time the URL is
routed:

```coffeescript
route 'login'
# 'views/login' is initialized and rendered

route ''
# 'views/site' is initialized and rendered
# 'views/header' is initialized and rendered
# 'views/footer' is initialized and rendered
# 'views/index' is initialized and rendered
# 'views/login' is disposed

route 'about'
# 'views/aboutme' is initialized and rendered
# 'views/index' is disposed

route 'login'
# 'views/login' is initialized and rendered
# 'views/index' is disposed
# 'views/footer' is disposed
# 'views/header' is disposed
# 'views/site' is disposed
```


## Long form

By default, when a controller requests a view to be composed, the composer
checks if the view instance exists and the options hash is equal. If that is
true the view is destroyed and composed.

By default, the compose method only allows for composing views.

The following example shows anoter way to use the compose method to allow for
just about anything. The check method should return true when it wishes
the composition to be disposed and the compose method to be called.
The composer will track and ensure proper disposal of whatever is returned from
the compose method (be it a view or an object with properties that have
dispose methods).

```coffeescript
  @compose 'something-strange',
    compose: ->
      composition = {}
      composition.model = new Model()
      composition.model.id = 42

      composition.view = new View
        model: composition.model

      composition.model.fetch()
      composition

    check: (composition) ->
      composition.model.id is 42 and
      typeof composition.view is typeof View
```
