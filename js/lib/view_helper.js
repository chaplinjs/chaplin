
define(['mediator', 'lib/utils'], function(mediator, utils) {
  'use strict';  Handlebars.registerHelper('partial', function(partialName, options) {
    return new Handlebars.SafeString(Handlebars.VM.invokePartial(Handlebars.partials[partialName], partialName, options.hash));
  });
  Handlebars.registerHelper('fb_img_url', function(fbId, type) {
    return new Handlebars.SafeString(utils.facebookImageURL(fbId, type));
  });
  Handlebars.registerHelper('if_logged_in', function(options) {
    if (mediator.user) {
      return options.fn(this);
    } else {
      return options.inverse(this);
    }
  });
  Handlebars.registerHelper('with', function(context, options) {
    if (!context || Handlebars.Utils.isEmpty(context)) {
      return options.inverse(this);
    } else {
      return options.fn(context);
    }
  });
  Handlebars.registerHelper('without', function(context, options) {
    var inverse;
    inverse = options.inverse;
    options.inverse = options.fn;
    options.fn = inverse;
    return Handlebars.helpers["with"].call(this, context, options);
  });
  Handlebars.registerHelper('with_user', function(options) {
    var context;
    context = mediator.user || {};
    return Handlebars.helpers["with"].call(this, context, options);
  });
  return null;
});
