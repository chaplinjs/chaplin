define ['models/model'], (Model) ->

  'use strict'

  class Navigation extends Model
    
    defaults:
      items: [
        { href: '/', title: 'Likes' }
      ]
