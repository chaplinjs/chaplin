---
layout: default
title: Chaplin.helpers
module_path: src/chaplin/lib/helpers.coffee
Chaplin: helpers
---

Helpers that use Chaplin components (global event bus etc.).

<h3 class="module-member" id="redirectTo">redirectTo([...params])</h3>
Does a in-app redirect:

1. `redirectTo('messages#show', {id: 2})` — to a named route.
2. `redirectTo({url: 'messages/2'})` — to an URL.
3. `redirectTo({controller: 'messages', action: 'show', params: {id: 2}})` — etc.

In the past, `!route:route[byName]` event was used for this purpose.

<h3 class="module-member" id="reverse">reverse(routeName[,...params])</h3>
Returns the URL for a named route, appropriately filling in values given as `params`.

For example, if you have declared the route

```coffeescript
match '/users/:login/profile', 'users#show'
```

```javascript
match('/users/:login/profile', 'users#show');
```

you can use

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

to yield `'/users/paulmillr/profile'`.
