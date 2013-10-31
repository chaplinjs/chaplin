---
layout: default
title: Using without jQuery and Underscore
Chaplin: Using without jQuery and Underscore
---

Thanks to [Exoskeleton](http://exosjs.com), Chaplin can be used without any dependencies other than Exoskeleton (Backbone) itself.

Exoskeleton is a faster and leaner Backbone for your HTML5 apps. It targets newer (IE9+) browsers, incorporates great new features and speed updates and plays great with Chaplin.

Instead of including 40K of gzipped javascript before Chaplin, you just need to include 8K — that's almost five times less!

To use Chaplin with Exoskeleton without dependencies on Underscore and jQuery:

* If you are using **AMD** (not Brunch):
  Define dummy underscore and jQuery modules before application start:

  ```javascript
  define('jquery', function(){});
  define('underscore', ['backbone'], function(Backbone){
    return Backbone.utils;
  });
  ```
* If you are using **Brunch**:
    1. Install exoskeleton: `bower install -s exoskeleton`
    2. Add override of chaplin dependencies to `bower.json`:

    ```
    "overrides": {
      "chaplin": {"dependencies": {"exoskeleton": "*"}}
    }
    ```

Example commit of switching Backbone app (Brunch) to Exoskeleton shown here: [paulmillr/ostio@514ba8](https://github.com/paulmillr/ostio/commit/514ba86d32ae174d144871c25f58825ea093de33)
