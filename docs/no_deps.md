---
layout: default
title: Using without jQuery and Underscore
Chaplin: Using without jQuery and Underscore
---

Thanks to [Exoskeleton](http://exosjs.com), Chaplin can be used without any dependencies than Exoskeleton (Backbone) itself.

Exoskeleton is a faster and leaner Backbone for your HTML5 apps. It targets newer (IE9+) browsers, incorporates great new features and speed updates and plays great with Chaplin.

Instead of including 40K of gzipped javascript before Chaplin, you just need to include 7K — that's almost six times less!

To use Chaplin with Exoskeleton without dependencies on Underscore and jQuery:

In AMD environment:

* Define dummy underscore and jQuery modules before application start:

```javascript
define('jquery', function(){});
define('underscore', ['backbone'], function(Backbone){
  return Backbone.utils;
});
```

In Brunch environment:

* Make sure to set `window._` to `Backbone.utils` in no-deps environment.
