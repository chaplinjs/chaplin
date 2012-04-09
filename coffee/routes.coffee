define ->
  'use strict'

  # The routes for the application. This module returns a function.
  # `match` is match method of the Router
  (match) ->

    match '', 'likes#index'
    match 'likes/:id', 'likes#show'
    match 'posts', 'posts#index'
