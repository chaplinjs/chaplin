---
layout: default
title: Getting started
---

## Download the boilerplate

The easiest way to start a Chaplin application is to download the boilerplate. It contains a recent build of Chaplin as well as all JavaScript libraries Chaplin depends upon:

* [Underscore](http://underscorejs.org/)
* [Backbone](http://backbonejs.org/)
* [jQuery](http://jquery.com/)
* [RequireJS](http://requirejs.org/) as AMD module loader

This is just the standard setup. You may substitute Underscore with [Lodash](http://lodash.com/docs), jQuery with [Zepto](http://zeptojs.com/) and RequireJS with different other AMD module loaders like [Curl](https://github.com/cujojs/curl).

The boilerplate comes in three flavours:

* [CoffeeScript code](https://github.com/chaplinjs/chaplin-boilerplate), if you develop your application in CoffeeScript
* [Plain JavaScript code](https://github.com/chaplinjs/chaplin-boilerplate-plain), if you develop your application in normal JavaScript
* [Brunch skeleton](https://github.com/paulmillr/brunch-with-chaplin), if you prefer using [Brunch](http://brunch.io) and synchronous common.js modules.

## Hello World!

The boilerplate contains the necessary files which inherit from the core Chaplin class.

## Integrating Chaplin into Rails 3

Use `requirejs-rails` gem.
