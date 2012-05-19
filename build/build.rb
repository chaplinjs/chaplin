#!/usr/bin/env ruby

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

CAT = "chaplin.coffee"
RAW = "chaplin.js"
MIN = "chaplin-min.js"
ZIP = "chaplin-min.js.gz"

puts 'Concatenate...'
File.open(CAT, 'w') do |cat_file|
  MODULES.each do |module_name|
    filename = "../src/#{module_name}.coffee"
    string = File.open(filename, 'r') { |file| file.read }
    string.gsub! /^\s*define(?=(?:\s+\[.*?\],)?\s*(?:\(.*?\))?\s*->)/m, "define '#{module_name}',"
    string = string.strip.concat("\n\n")
    cat_file.write string
  end
end

puts 'Coffee...'
`coffee --compile #{CAT}`

puts 'Uglify...'
`uglifyjs --output #{MIN} #{RAW}`

puts 'Compress...'
`gzip -9 -c #{MIN} > #{ZIP}`

puts 'Done.'