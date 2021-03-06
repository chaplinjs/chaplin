![Chaplin](http://s3.amazonaws.com/imgly_production/3401027/original.png)

[![Build Status](https://travis-ci.org/chaplinjs/chaplin.svg?branch=master)](https://travis-ci.org/chaplinjs/chaplin)

# An Application Architecture Using Backbone.js

## Introduction

Chaplin is an architecture for JavaScript applications using the [Backbone.js](http://backbonejs.org/) library.

All information, commercial support contacts and examples are available at [chaplinjs.org](http://chaplinjs.org), comprehensive documentation and class reference can be found at [docs.chaplinjs.org](http://docs.chaplinjs.org).

[Download the latest release on chaplinjs.org](http://chaplinjs.org/#downloads). See below on how to compile from source manually.

## Building Chaplin

The Chaplin source files are originally written in the [CoffeeScript](http://coffeescript.org/) meta-language. However, the Chaplin library file is a compiled JavaScript file which defines the `chaplin` module.

Our build script compiles the CoffeeScripts and bundles them into one file. To run the script, follow these steps:

1. Download and install [Node.js](http://nodejs.org/).
2. Open a shell (aka terminal aka command prompt) and type in the commands in the following steps.
3. Change into the Chaplin root directory.
4. Install all dependencies

   ```
   npm install
   ```

5. Start the build

   ```
   npm run build
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

or alternatively, if you want code coverage reports

   ```
   npm run coverage
   ```

Generated code coverage reports may be viewed by opening `coverage/index.html` in your browser.

![Ending](http://s3.amazonaws.com/imgly_production/3362023/original.jpg)

## [The Cast](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#the-cast)

## [The Producers](https://github.com/chaplinjs/chaplin/blob/master/AUTHORS.md#the-producers)
