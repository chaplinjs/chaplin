define ['lib/utils'], (utils) ->

  # Application-specific view helpers
  # ---------------------------------

  # Facebook image URLs
  Handlebars.registerHelper 'fb_img_url', (fbId, type) ->
    new Handlebars.SafeString utils.facebookImageURL(fbId, type)

  null