#!/bin/bash

command -v coffee > /dev/null 2>&1 || { echo "CoffeeScript needs to be installed using `npm install -g coffee`" >&2; exit 1; }
command -v r.js > /dev/null 2>&1 || { echo "RequireJS needs to be installed using `npm install -g requirejs`" >&2; exit 1; }

coffee --compile --bare --output js ../src/

r.js -o rjs-config.js out=chaplin-rjs.js optimize=none
r.js -o rjs-config.js out=chaplin-rjs.min.js optimize=uglify

gzip -9 -c chaplin-rjs.min.js > chaplin-rjs.min.js.gz

rm -r js
