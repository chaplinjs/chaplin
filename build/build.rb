#!/usr/bin/env ruby
require 'json'
require './convert'

MODULES = %w(
chaplin/application
chaplin/mediator
chaplin/dispatcher
chaplin/controllers/controller
chaplin/models/collection
chaplin/models/model
chaplin/views/layout
chaplin/views/view
chaplin/views/collection_view
chaplin/lib/route
chaplin/lib/router
chaplin/lib/subscriber
chaplin/lib/support
chaplin/lib/sync_machine
chaplin/lib/utils
chaplin
)

LOADERS = %w(amd commonjs)

LOADERS.each do |loader|

end

def concat_path(loader)
  "chaplin-#{loader}.coffee"
end

def compile_path(loader)
  "chaplin-#{loader}.js"
end

def minify_path(loader)
  "chaplin-#{loader}-min.js"
end

def gzip_path(loader)
  "chaplin-#{loader}-min.js.gz"
end

def get_version
  File.open(File.join('..', 'package.json'), 'r') do |file|
    JSON.parse(file.read)['version']
  end
end

HEADER = <<HERE
###
Chaplin #{get_version}.

Chaplin may be freely distributed under the MIT license.
For all details and documentation:
http://github.com/chaplinjs/chaplin
###

HERE

def concat
  puts 'Concatenate...'

  amd = MODULES.map do |module_name|
    filename = "../src/#{module_name}.coffee"
    string = File.open(filename, 'r') { |file| file.read }
    string.gsub! /^\s*define(?=(?:\s+\[.*?\],)?\s*(?:\(.*?\))?\s*->)/m, "define '#{module_name}',"
    string.strip.concat("\n\n")
  end.join('')

  commonjs = convert(amd)

  File.open(concat_path('amd'), 'w') do |file|
    file.write(HEADER + amd)
  end
  File.open(concat_path('commonjs'), 'w') do |file|
    file.write(HEADER + commonjs)
  end
end

def compile(loader)
  puts 'Compile...'
  `coffee --compile #{concat_path(loader)}`
end

def minify(loader)
  puts 'Minify...'
  `uglifyjs --output #{minify_path(loader)} #{compile_path(loader)}`
end

def gzip(loader)
  puts 'Gzip...'
  `gzip -9 -c #{minify_path(loader)} > #{gzip_path(loader)}`
end

concat
LOADERS.each do |loader|
  puts "Doing stuff for #{loader}"
  compile(loader)
  minify(loader)
  gzip(loader)
end

puts 'Copy to test folder...'
`cp #{RAW} ../test/lib/chaplin.js`

puts 'Done.'