#!/bin/bash
r.js -o build_config.js out=chaplin.js optimize=none
r.js -o build_config.js out=chaplin-min.js optimize=uglify
