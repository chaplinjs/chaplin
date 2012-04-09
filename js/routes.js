
define(function() {
  'use strict';  return function(match) {
    match('', 'likes#index');
    match('likes/:id', 'likes#show');
    return match('posts', 'posts#index');
  };
});
