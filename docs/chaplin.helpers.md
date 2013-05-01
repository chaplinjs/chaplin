# [Chaplin.helpers](../src/chaplin/lib/helpers.coffee)

Helpers that use Chaplin components (global event bus etc).

## reverse(routeName[, ...params])
Returns the url for a named route and any params.

For example, if you had declared this route

```javascript
match('/users/:login/profile', 'users#show');
```

you may use:

```javascript
Chaplin.helpers.reverse('users#show', {login: 'paulmillr'});
// => '/users/paulmillr/profile'
```
