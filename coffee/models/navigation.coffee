define ['chaplin/models/model'], (ChaplinModel) ->
  'use strict'

  class Navigation extends ChaplinModel
    defaults:
      items: [
        {href: '/', title: 'Likes Browser'}
        {href: '/posts', title: 'Wall Posts'}
      ]
