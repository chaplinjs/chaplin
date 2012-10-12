#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require './convert'

MODULES = %w(
chaplin/application
chaplin/mediator
chaplin/dispatcher
chaplin/composer
chaplin/views/composition
chaplin/controllers/controller
chaplin/models/collection
chaplin/models/model
chaplin/views/layout
chaplin/views/view
chaplin/views/collection_view
chaplin/lib/route
chaplin/lib/router
chaplin/lib/event_broker
chaplin/lib/support
chaplin/lib/sync_machine
chaplin/lib/utils
chaplin
)

LOADERS = %w(amd commonjs)
COMMIT_HASH = `git rev-parse --verify HEAD`.slice(0, 7)
VERSION = File.open(File.join('..', 'package.json'), 'r') do |file|
  JSON.parse(file.read)['version']
end
SUFFIX = VERSION.include?('-pre') ? "#{VERSION}-#{COMMIT_HASH}" : VERSION

def get_path(loader, type)
  extension = case type
  when 'concat' then '.coffee'
  when 'compile' then '.js'
  when 'minify' then '-min.js'
  when 'gzip' then '-min.js.gz'
  end

  File.join("#{loader}", "chaplin-#{SUFFIX}") + extension
end

HEADER = <<HERE
###
Chaplin #{VERSION}.

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

  FileUtils.rm_rf(%w[amd commonjs])
  Dir.mkdir('amd')
  Dir.mkdir('commonjs')

  File.open(get_path('amd', 'concat'), 'w') do |file|
    file.write(HEADER + amd)
  end
  File.open(get_path('commonjs', 'concat'), 'w') do |file|
    file.write(HEADER + commonjs)
  end
end

def compile(loader)
  puts 'Compile...'
  `coffee --compile #{get_path(loader, 'concat')}`
end

def minify(loader)
  puts 'Minify...'
  `uglifyjs --output #{get_path(loader, 'minify')} #{get_path(loader, 'compile')}`
end

def gzip(loader)
  puts 'Gzip...'
  `gzip -9 -c #{get_path(loader, 'minify')} > #{get_path(loader, 'gzip')}`
end

def build
  concat()
  LOADERS.each do |loader|
    puts "Doing stuff for #{loader}"
    compile(loader)
    minify(loader)
    gzip(loader)
  end

  puts 'Done.'
end

build()
