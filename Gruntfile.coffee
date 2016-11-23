'use strict'

# Package
# =======
pkg = require './package.json'

banner = """
/*!
 * Chaplin #{pkg.version}
 *
 * Chaplin may be freely distributed under the MIT license.
 * For all details and documentation:
 * http://chaplinjs.org
 */

"""

module.exports = (grunt) ->

  # Configuration
  # =============
  grunt.initConfig {

    # Package
    # -------
    pkg

    coffeelint:
      src: 'src/**/*.coffee'
      test: 'test/*.coffee'
      grunt: 'Gruntfile.coffee'
      options:
        configFile: 'coffeelint.json'

    clean: ['./tmp']

    coffee:
      test:
        expand: true,
        cwd: './test/',
        src: ['*.coffee'],
        dest: './tmp/test/',
        ext: '.js'

    mochaTest:
      native:
        options:
          reporter: 'spec'
          require: [
            ->
              global._$coffeeIstanbul = {}
            'babel-register'
            'jsdom-assign'
            -> require.cache[require.resolve 'jquery'] = {}
            'backbone.nativeview'
          ]
        src: 'tmp/test/*.js'
      jquery:
        options:
          reporter: 'spec'
          require: [
            ->
              global._$coffeeIstanbul = {}
            'babel-register'
            'jsdom-assign'
          ]
        src: 'tmp/test/*.js'

    makeReport:
      src: 'coverage/coverage-coffee.json',
      options:
        type: 'html'
        dir: 'coverage'

    rollup:
      options:
        plugins: [
          require('rollup-plugin-coffee-script')()
          require('rollup-plugin-node-resolve')(extensions: ['.coffee'])
        ]
        external: ['underscore', 'backbone']
        globals:
          backbone: 'Backbone'
          underscore: '_'
        format: 'umd'
        moduleName: 'Chaplin'
        banner: banner

      dist:
        files:
          'build/chaplin.js': 'src/chaplin.coffee'

    # Minify
    # ======
    uglify:
      options:
        mangle: true
      universal:
        files:
          'build/chaplin.min.js': 'build/chaplin.js'

    # Compression
    # ===========
    compress:
      files:
        src: 'build/chaplin.min.js'
        dest: 'build/chaplin.min.js.gz'

    transbrute:
      docs:
        remote: 'git@github.com:chaplinjs/chaplin.git'
        branch: 'gh-pages'
        files: [
          { expand: true, cwd: 'docs/', src: '**/*' }
        ]
      downloads:
        message: "Release #{pkg.version}."
        tag: pkg.version
        tagMessage: "Version #{pkg.version}."
        remote: 'git@github.com:chaplinjs/downloads.git'
        branch: 'gh-pages'
        files: [
          {
            expand: true,
            cwd: 'build/',
            src: 'chaplin.{js,min.js}'
          },
          {
            dest: 'bower.json',
            body: {
              name: 'chaplin',
              repo: 'chaplinjs/downloads',
              version: pkg.version,
              main: 'chaplin.js',
              scripts: ['chaplin.js'],
              dependencies: { backbone: '1.x' }
            }
          },
          {
            dest: 'component.json',
            body: {
              name: 'chaplin',
              repo: 'chaplinjs/downloads',
              version: pkg.version,
              main: 'chaplin.js',
              scripts: ['chaplin.js'],
              dependencies: { 'bower_components/backbone': '1.x' }
            }
          },
          {
            dest: 'package.json',
            body: {
              name: 'chaplin',
              version: pkg.version,
              description: 'Chaplin.js',
              main: 'chaplin.js',
              scripts: { test: 'echo "Error: no test specified" && exit 1' },
              repository: {
                type: 'git', url: 'git://github.com/chaplinjs/downloads.git'
              },
              author: 'Chaplin team',
              license: 'MIT',
              bugs: { url: 'https://github.com/chaplinjs/downloads/issues' },
              dependencies: pkg.dependencies
            }
          }
        ]

    # Watching for changes
    # ====================
    watch:
      coffee:
        files: ['src/**/*.coffee', 'test/*.coffee']
        tasks: ['test']
  }

  # Dependencies
  # ============
  for name of pkg.devDependencies when name.startsWith 'grunt-'
    grunt.loadNpmTasks name

  # Releasing
  # =========

  grunt.registerTask 'check:versions:component', 'Check that package.json and bower.json versions match', ->
    componentVersion = grunt.file.readJSON('bower.json').version
    unless componentVersion is pkg.version
      grunt.fail.warn "bower.json is version #{componentVersion}, package.json is #{pkg.version}."
    else
      grunt.log.ok()

  grunt.registerTask 'check:versions:changelog', 'Check that CHANGELOG.md is up to date', ->
    # Require CHANGELOG.md to contain "Chaplin VERSION (DIGIT"
    changelogMd = grunt.file.read('CHANGELOG.md')
    unless RegExp("Chaplin #{pkg.version} \\(\\d").test changelogMd
      grunt.fail.warn "CHANGELOG.md does not seem to be updated for #{pkg.version}."
    else
      grunt.log.ok()

  grunt.registerTask 'check:versions:docs', 'Check that package.json and docs versions match', ->
    template = grunt.file.read path.join('docs', '_layouts', 'default.html')
    match = template.match /^version: ((\d+)\.(\d+)\.(\d+)(?:-[\dA-Za-z\-]*)?)$/m
    unless match
      grunt.fail.warn "Version missing in docs layout."
    docsVersion = match[1]
    unless docsVersion is pkg.version
      grunt.fail.warn "Docs layout is version #{docsVersion}, package.json is #{pkg.version}."
    else
      grunt.log.ok()

  grunt.registerTask 'check:versions', [
    'check:versions:component',
    'check:versions:changelog',
    'check:versions:docs'
  ]

  grunt.registerTask 'release:git', 'Check context, commit and tag for release.', ->
    prompt = require 'prompt'
    prompt.start()
    prompt.message = prompt.delimiter = ''
    prompt.colors = false
    # Command/query wrapper, turns description object for `spawn` into runner
    command = (desc, message) ->
      (next) ->
        grunt.log.writeln message if message
        grunt.util.spawn desc, (err, result, code) -> next(err)
    query = (desc) ->
      (next) -> grunt.util.spawn desc, (err, result, code) -> next(err, result)
    # Help checking input from prompt. Returns a callback that calls the
    # original callback `next` only if the input was as expected
    checkInput = (expectation, next) ->
      (err, input) ->
        unless input and input.question is expectation
          grunt.fail.warn "Aborted: Expected #{expectation}, got #{input}"
        next()

    steps = []
    continuation = this.async()

    # Check for master branch
    steps.push query(cmd: 'git', args: ['rev-parse', '--abbrev-ref', 'HEAD'])
    steps.push (result, next) ->
      result = result.toString().trim()
      if result is 'master'
        next()
      else
        prompt.get([
            description: "Current branch is #{result}, not master. 'ok' to continue, Ctrl-C to quit."
            pattern: /^ok$/, required: true
          ],
          checkInput('ok', next)
        )
    # List dirty files, ask for confirmation
    steps.push query(cmd: 'git', args: ['status', '--porcelain'])
    steps.push (result, next) ->
      grunt.fail.warn "Nothing to commit." unless result.toString().length

      grunt.log.writeln "The following dirty files will be committed:"
      grunt.log.writeln result
      prompt.get([
          description: "Commit these files? 'ok' to continue, Ctrl-C to quit.",
          pattern: /^ok$/, required: true
        ],
        checkInput('ok', next)
      )

    # Commit
    steps.push command(cmd: 'git', args: ['commit', '-a', '-m', "Release #{pkg.version}"])

    # Tag
    steps.push command(cmd: 'git', args: ['tag', '-a', pkg.version, '-m', "Version #{pkg.version}"])

    grunt.util.async.waterfall steps, continuation

  grunt.registerTask 'release', [
    'check:versions'
    'release:git'
    'build'
    'transbrute:docs'
    'transbrute:downloads'
  ]

  # Publish Documentation
  # =====================
  grunt.registerTask 'docs:publish', ['check:versions:docs', 'transbrute:docs']

  # Tests
  # =====

  grunt.registerTask 'instrument', ->
    {CoverageInstrumentor} = require('coffee-coverage')
    coverageInstrumentor = new CoverageInstrumentor({
      instrumentor: 'istanbul'
    })
    coverageInstrumentor.instrument('./src', './tmp/src', bare: true)

  grunt.registerTask 'lint', 'coffeelint'
  grunt.registerTask 'test', ['clean', 'instrument', 'coffee:test', 'mochaTest:native']
  grunt.registerTask 'test:jquery', ['clean', 'instrument', 'coffee:test', 'mochaTest:jquery']

  # Coverage
  # ========
  grunt.registerTask 'coverage', ['mochaTest:native', 'makeReport']

  # Building
  # ========
  grunt.registerTask 'build', ['rollup', 'uglify', 'compress']

  # Default
  # =======
  grunt.registerTask 'default', ['lint', 'test']
