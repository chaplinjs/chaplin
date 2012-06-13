# Replace AMD definitions to CommonJS.

def make_module_definition(name, source)
  "require.define #{name}: (require, exports, module) ->#{source}"
end

def convert_one(raw_modules = '', raw_module_names = '')
  unless raw_modules
    return ''
  end

  # "'lib/utils' 'models/model', 'models/collection'"
  # => ['lib/utils', 'models/model', 'models/collection']
  modules = raw_modules.strip.split(' ').map do |mdl|
    mdl.gsub(',', '')
  end

  # utils, Model, Collection
  # => ['utils', 'Model', 'Collection']
  module_names = raw_module_names.strip.split(',').map(&:strip)

  definitions_arr = []

  module_names.each_with_index do |module_name, index|
    # "  utils = require 'lib/utils'"
    definitions_arr << "  #{module_name} = require #{modules[index]}"
  end

  "\n" + definitions_arr.join("\n") + "\n"
end

def convert(source)
  # define 'name', ['req1', 'req2', 'req3'], (req1, req2, req3) ->
  re = /(define ('.*'),(?: \[([,\s\w\/_']*)\],)? (?:\(([\s\w,\$_]*)\) )?->)/

  # Copy string because we're using mutable replace method.
  # Scan it for regexp then.
  String.new(source).scan(re).each do |match|
    src = match[0]  # The whole shit.
    name = match[1]  # module name.
    raw_modules = match[2]  # (optional) list of module paths.
    raw_module_names = match[3]  # (optional) list of module names.
    definition = convert_one(raw_modules, raw_module_names)
    source[src] = make_module_definition(name, definition)
  end

  # Replace all 'use strict's with one strict at the top of file.
  "'use strict'\n\n" + source.gsub(/\s*'use strict'/, '')
end

if __FILE__ == $0
  puts convert(STDIN.read)
end
