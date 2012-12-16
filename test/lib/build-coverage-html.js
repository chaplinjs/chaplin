var jade = require('jade');
var fs = require('fs');

// Strings for code coverage classes
function coverageClass(n) {
  if (n >= 75) return 'high';
  if (n >= 50) return 'medium';
  if (n >= 25) return 'low';
  return 'terrible';
}

// Read in templates
var file = __dirname + '/templates/coverage.jade';
var str = fs.readFileSync(file, 'utf8');
var fn = jade.compile(str, { filename: file });

// Read JSON from stdin
var cov = JSON.parse(fs.readFileSync('/dev/stdin').toString());

// Dump HTML
var outFile = __dirname + '/../coverage.html'
fs.appendFileSync(outFile, fn({
    cov: cov,
    coverageClass: coverageClass
}));
