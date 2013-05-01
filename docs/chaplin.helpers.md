# [Chaplin.helpers](../src/chaplin/lib/helpers.coffee)

Helpers that use Chaplin components (global event bus etc).

## reverse(routeName[, ...params])
Returns the url for a named route and any params.

For example, if you had declared this route

```coffeescript
# CoffeeScript
match '/users/:login/profile', 'users#show'
```

```javascript
// JavaScript
match('/users/:login/profile', 'users#show');
```

you may use:

```coffeescript
# CoffeeScript
Chaplin.helpers.reverse 'users#show', login: 'paulmillr'
# or
Chaplin.helpers.reverse 'users#show', ['paulmillr']
```

```javascript
// JavaScript
Chaplin.helpers.reverse('users#show', {login: 'paulmillr'});
// or
Chaplin.helpers.reverse('users#show', ['paulmillr']);
```

this will return `'/users/paulmillr/profile'`
