#!/bin/bash
r.js -o build_config.js out=build/chaplin.js optimize=none
r.js -o build_config.js out=build/chaplin-min.js optimize=uglify