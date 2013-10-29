![Chaplin](http://s3.amazonaws.com/imgly_production/3401027/original.png)

[![Stories in Ready](https://badge.waffle.io/chaplinjs/chaplin.png?label=ready)](http://waffle.io/chaplinjs/chaplin)
[![Build Status](https://travis-ci.org/chaplinjs/chaplin.png?branch=topics/backbone-options)](https://travis-ci.org/chaplinjs/chaplin)

# An Application Architecture Using Backbone.js

## Introduction

Chaplin is an architecture for JavaScript applications using the [Backbone.js](http://documentcloud.github.com/backbone/) library.

All information, commercial support contacts and examples are available at [chaplinjs.org](http://chaplinjs.org), comprehensive documentation and class reference can be found at [docs.chaplinjs.org](http://docs.chaplinjs.org).

[Download the latest release on chaplinjs.org](http://chaplinjs.org/#downloads). See below on how to compile from source manually.

## Building Chaplin

The Chaplin source files are originally written in the [CoffeeScript](http://coffeescript.org/) meta-language. However, the Chaplin library file is a compiled JavaScript file which defines the `chaplin` module.

Our build script compiles the CoffeeScripts and bundles them into one file. To run the script, follow these steps:

1. Download and install [Node.js](http://nodejs.org/).
2. Open a shell (aka terminal aka command prompt) and type in the commands in the following steps.
3. Install the Node package for the grunt command line interface globally.

   ```sh
   sudo npm install -g grunt-cli
   ```

   On Windows, you can omit the `sudo` command at the beginning.

4. Change into the Chaplin root directory.
5. Start the build (will install dependencies and build).

   ```
   npm install
   ```

This creates these files in `build` dir:

* `chaplin.js` – The library as a compiled JavaScript file.
* `chaplin.min.js` – Minified. For production use you should pick this.

## Running the Tests

Chaplin aims to be fully unit-tested. At the moment most of the modules are covered by Mocha tests.

How to run the tests:

1. Follow the steps for [building chaplin](#building-chaplin).
2. Open a shell (aka terminal aka command prompt) and type in the commands in the following steps.
3. Change into the Chaplin root directory.
4. Start the test runner.

   ```
   npm test
   ```

Note that you can now additionally open `test/index.html` to run the tests in your browser (instead of in node).
Furthermore code coverage reports are generated and may be viewed by opening `test/coverage/index.html` in your browser.

To run tests with different params **with exoskeleton**:

* **without jQuery / underscore:** append `?type=exos` to browser URL
* **with jQuery / underscore:**: append `?type=deps` to browser URL

![Ending](http://s3.amazonaws.com/imgly_production/3362023/original.jpg)

## [The Cast](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#the-cast)

## [The Producers](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#the-producers)
