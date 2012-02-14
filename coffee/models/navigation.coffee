define ['models/model'], (Model) ->

  'use strict'

  class Navigation extends Model
    
    defaults:
      items: [
        { href: '/', title: 'Your Likes' }
        { href: '/posts', title: 'Wall Posts' }
      ]
