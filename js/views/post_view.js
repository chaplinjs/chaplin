var __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

define(['views/view', 'text!templates/post.hbs'], function(View, template) {
  'use strict';
  var PostView;
  return PostView = (function(_super) {

    __extends(PostView, _super);

    function PostView() {
      PostView.__super__.constructor.apply(this, arguments);
    }

    PostView.prototype.template = template;

    PostView.prototype.tagName = 'li';

    PostView.prototype.className = 'post';

    return PostView;

  })(View);
});
