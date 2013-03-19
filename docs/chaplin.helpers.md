# [Chaplin.helpers](../src/chaplin/lib/helpers.coffee)

Helpers that use Chaplin components (global event bus etc).

## reverse(routeName[, ...params])
Returns the url for a named route and any params.

```coffeescript
# If you had declared this route:
match '/users/:login/profile', name: 'user-profile'

# you may use
Chaplin.helpers.reverse 'user-profile', login: 'paulmillr'
# => '/users/paulmillr/profile'
```
