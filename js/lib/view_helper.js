
define(['lib/utils'], function(utils) {
  Handlebars.registerHelper('fb_img_url', function(fbId, type) {
    return new Handlebars.SafeString(utils.facebookImageURL(fbId, type));
  });
  return null;
});
