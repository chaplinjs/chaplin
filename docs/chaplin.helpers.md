---
layout: default
title: Chaplin.helpers
module_path: src/chaplin/lib/helpers.coffee
---

Helpers that use Chaplin components (global event bus etc).

## reverse(routeName[, ...params])
Returns the url for a named route and any params.

For example, if you had declared this route

```coffeescript
match '/users/:login/profile', 'users#show'
```

```javascript
match('/users/:login/profile', 'users#show');
```

you may use:

```coffeescript
Chaplin.helpers.reverse 'users#show', login: 'paulmillr'
# or
Chaplin.helpers.reverse 'users#show', ['paulmillr']
```

```javascript
Chaplin.helpers.reverse('users#show', {login: 'paulmillr'});
// or
Chaplin.helpers.reverse('users#show', ['paulmillr']);
```

this will return `'/users/paulmillr/profile'`
