fs = require 'fs'
sysPath = require 'path'
convertExports = require './build/convert_exports'

try
  require 'shelljs/global'
catch error
  console.log 'You will need to install "shelljs":'
  console.log 'npm install shelljs'
  process.exit(1)

convertAmdToCommonJs = (amdString) ->
  GLOBALS = '''
require.define
  'jquery': (require, exports, module) -> module.exports = $
  'underscore': (require, exports, module) -> module.exports = _
  'backbone': (require, exports, module) -> module.exports = Backbone

  '''

  makeModuleDefinition = (name, source) ->
    "require.define #{name}: (exports, require, module) ->#{source}"

  convertModule = (rawModules = '', rawModuleNames = '') ->
    return '' unless rawModules

    # "'lib/utils' 'models/model', 'models/collection'"
    # => ['lib/utils', 'models/model', 'models/collection']
    modules = rawModules.trim().split(/\s+/)

    # utils, Model, Collection
    # => ['utils', 'Model', 'Collection']
    moduleNames = rawModuleNames.trim().split(',').map (moduleName) ->
      moduleName.trim()

    definitions = moduleNames
      .map (moduleName, index) ->
        "  #{moduleName} = require #{modules[index]}"
      .join('\n')

    "\n#{definitions}\n"

  convertModules = (string) ->
    re = /define\s('.*'),(?:\s\[([,\s\w\/_']*)\],)?\s(?:\(([\s\w,\$_]*)\)\s)?->/g
    # match = re.exec string
    replacements = []
    while (match = re.exec string)
      do (match) ->
        [original, name, rawModules, rawModuleNames] = match
        definition = convertModule rawModules, rawModuleNames
        current = makeModuleDefinition name, definition
        replacements.push [original, current]
    for [original, current] in replacements
      string = string.replace original, current
    string

  # Replace all 'use strict's with one strict at the top of file.
  consolidateStricts = (string) ->
    replaced = string.replace(/\s*'use strict'/g, '')
    "'use strict'\n\n#{GLOBALS}\n#{replaced}"

  consolidateStricts convertExports convertModules amdString

addModuleNameToSource = (moduleName) ->
  re = /^\s*define(?=(?:\s+\[[\s\S]*?\],)?\s*(?:\([\s\S]*?\))?\s*->)/
  fs.readFileSync("src/#{moduleName}.coffee")
    .toString()
    .replace(re, "define '#{moduleName}',")
    .trim()

module.exports = {convertAmdToCommonJs, addModuleNameToSource}

build = ->
  MODULES = [
    'chaplin/application'
    'chaplin/mediator'
    'chaplin/dispatcher'
    'chaplin/controllers/controller'
    'chaplin/models/collection'
    'chaplin/models/model'
    'chaplin/views/layout'
    'chaplin/views/view'
    'chaplin/views/collection_view'
    'chaplin/lib/route'
    'chaplin/lib/router'
    'chaplin/lib/delayer'
    'chaplin/lib/event_broker'
    'chaplin/lib/support'
    'chaplin/lib/sync_machine'
    'chaplin/lib/utils'
    'chaplin'
  ]

  LOADERS = ['amd', 'commonjs']
  COMMIT_HASH = exec('git rev-parse --verify HEAD', silent: yes).output.slice(0, 7)
  VERSION = (JSON.parse fs.readFileSync 'package.json').version
  SUFFIX = if VERSION.indexOf('-pre') >= 0
    "#{VERSION}-#{COMMIT_HASH}"
  else
    VERSION

  getPath = (loader, type) ->
    extension = switch type
      when 'concat' then '.coffee'
      when 'compile' then '.js'
      when 'minify' then '-min.js'
      when 'gzip' then '-min.js.gz'
    sysPath.join('build', "#{loader}", "chaplin-#{SUFFIX}") + extension

  HEADER = """
  ###
Chaplin #{VERSION}.

Chaplin may be freely distributed under the MIT license.
For all details and documentation:
http://chaplinjs.org
  ###


  """

  concat = ->
    echo 'Concatenate...'
    concatenated = {}
    concatenated.amd = MODULES.map(addModuleNameToSource).join('\n\n')
    concatenated.commonjs = convertAmdToCommonJs concatenated.amd

    LOADERS.forEach (loader) ->
      dirPath = sysPath.join 'build', loader
      rm '-R', dirPath
      mkdir dirPath
      fs.writeFileSync getPath(loader, 'concat'), HEADER + concatenated[loader]

  compile = (loader) ->
    echo 'Compile...'
    exec "coffee --compile #{getPath(loader, 'concat')}"

  minify = (loader) ->
    echo 'Minify...'
    minifyPath = getPath(loader, 'minify')
    compilePath = getPath(loader, 'compile')
    exec "uglifyjs --output #{minifyPath} #{compilePath}", silent: yes

  gzip = (loader) ->
    echo 'Gzip...'
    exec(
      "gzip -9 -c #{getPath(loader, 'minify')} > #{getPath(loader, 'gzip')}",
      silent: yes
    )

  concat()
  LOADERS.forEach (loader) ->
    echo "Doing stuff for #{loader}"
    compile loader
    minify loader
    gzip loader
  echo 'Done.'

task 'build', 'Build Chaplin from source', build

task 'test', 'Test', ->
  exec 'coffee --bare --output test/js/ src/'
  exec 'coffee --bare --output test/js/ test/spec/'
  echo 'Compiled tests, you can now open test/index.html and run them'
