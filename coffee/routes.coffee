define ->
  'use strict'

  # The Routes for the application
  (match) ->

    match '', 'likes#index'
    match 'likes/:id', 'likes#show'
    match 'posts', 'posts#index'
