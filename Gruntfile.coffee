module.exports = (grunt) ->

  # Utilities
  # =========
  path = require 'path'

  # Package
  # =======
  pkg = require './package.json'

  # Modules
  # =======
  # TODO: Remove this as soon as uRequire releases 0.3 which will able to
  #  do this for us in the right order magically.
  modules = [
    'temp/chaplin/application.js'
    'temp/chaplin/mediator.js'
    'temp/chaplin/dispatcher.js'
    'temp/chaplin/composer.js'
    'temp/chaplin/controllers/controller.js'
    'temp/chaplin/models/collection.js'
    'temp/chaplin/models/model.js'
    'temp/chaplin/views/layout.js'
    'temp/chaplin/views/view.js'
    'temp/chaplin/views/collection_view.js'
    'temp/chaplin/lib/route.js'
    'temp/chaplin/lib/router.js'
    'temp/chaplin/lib/delayer.js'
    'temp/chaplin/lib/event_broker.js'
    'temp/chaplin/lib/support.js'
    'temp/chaplin/lib/composition.js'
    'temp/chaplin/lib/sync_machine.js'
    'temp/chaplin/lib/utils.js'
    'temp/chaplin/lib/helpers.js'
    'temp/chaplin.js'
  ]

  # Configuration
  # =============
  grunt.initConfig

    # Package
    # -------
    pkg: pkg

    # Clean
    # -----
    clean:
      build: 'build'
      temp: 'temp'
      components: 'components'
      test: ['test/temp*', 'test/coverage']

    # Compilation
    # -----------
    coffee:
      compile:
        files: [
          expand: true
          dest: 'temp/'
          cwd: 'src'
          src: '**/*.coffee'
          ext: '.js'
        ]

      test:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'test/spec'
          src: '**/*.coffee'
          ext: '.js'
        ]

      options:
        bare: true

    # Module conversion
    # -----------------
    urequire:
      AMD:
        bundlePath: 'temp/'
        outputPath: 'temp/'

        options:
          forceOverwriteSources: true
          relativeType: 'bundle'

    # Publishing via Git
    # ------------------
    transbrute:
      docs:
        remote: 'git@github.com:chaplinjs/chaplin.git'
        branch: 'gh-pages'
        files: [
          { expand: true, cwd: 'docs/', src: '**/*' }
        ]
      downloads:
        message: "Release #{pkg.version}."
        remote: 'git@github.com:chaplinjs/downloads.git'
        branch: 'gh-pages'
        files: [
          { expand: true, cwd: 'build/', src: '{amd,brunch}/chaplin.{js,min.js}' },
          {
            dest: 'component.json',
            body: {
              name: 'chaplin',
              version: pkg.version,
              main: 'amd/chaplin.js',
              dependencies: { backbone: '>= 1.0.0' }
            }
          }
        ]

    # Module naming
    # -------------
    # TODO: Remove this when uRequire hits 0.3
    copy:
      commonjs:
        files: [
          expand: true
          dest: 'temp/'
          cwd: 'temp'
          src: '**/*.js'
        ]

        options:
          processContent: (content, path) ->
            name = ///temp/(.*)\.js///.exec(path)[1]
            """
            require.define({'#{name}': function(exports, require, module) {
            #{content}
            }});
            """

      amd:
        files: [
          expand: true
          dest: 'temp/'
          cwd: 'temp'
          src: '**/*.js'
        ]

        options:
          processContent: (content, path) ->
            name = ///temp/(.*)\.js///.exec(path)[1]
            content.replace ///define\(///, "define('#{name}',"

      test:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'temp'
          src: '**/*.js'
        ]

      beforeInstrument:
        files: [
          expand: true
          dest: 'test/temp-original/'
          cwd: 'test/temp'
          src: '**/*.js'
        ]

      afterInstrument:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'test/temp-original'
          src: '**/*.js'
        ]

    # Module concatenation
    # --------------------
    # TODO: Remove this when uRequire hits 0.3
    concat:
      options:
        separator: ';'
        banner: '''
        /*!
         * Chaplin <%= pkg.version %>
         *
         * Chaplin may be freely distributed under the MIT license.
         * For all details and documentation:
         * http://chaplinjs.org
         */


        '''

      amd:
        files: [
          dest: 'build/amd/<%= pkg.name %>.js'
          src: modules
        ]

      commonjs:
        files: [
          dest: 'build/commonjs/<%= pkg.name %>.js'
          src: modules
        ]

      brunch:
        files: [
          dest: 'build/brunch/<%= pkg.name %>.js'
          src: modules
        ]

        options:
          banner: '''
          /*!
           * Chaplin <%= pkg.version %>
           *
           * Chaplin may be freely distributed under the MIT license.
           * For all details and documentation:
           * http://chaplinjs.org
           */

          // Dirty hack for require-ing backbone and underscore.
          (function() {
            var deps = {
              backbone: window.Backbone, underscore: window._
            };

            for (var name in deps) {
              (function(name) {
                var definition = {};
                definition[name] = function(exports, require, module) {
                  module.exports = deps[name];
                };

                try {
                  require(item);
                } catch(e) {
                  require.define(definition);
                }
              })(name);
            }
          })();


          '''

    # Lint
    # ----
    coffeelint:
      source: 'src/**/*.coffee'
      grunt: 'Gruntfile.coffee'

    # Instrumentation
    # ---------------
    instrument:
      files: [
        'test/temp/chaplin.js'
        'test/temp/chaplin/**/*.js'
      ]

      options:
        basePath: '.'

    storeCoverage:
      options:
        dir : '.'
        json : 'coverage.json'
        coverageVar : '__coverage__'

    makeReport:
      src: 'coverage.json'
      options:
        type: 'html'
        dir: 'test/coverage'

    # Browser dependencies
    # --------------------
    bower:
      install:
        options:
          targetDir: './test/components'
          cleanup: true

    # Test runner
    # -----------
    mocha:
      index:
        src: ['test/index.html']
        # options:
        #   grep: 'autoAttach'
        #   mocha:
        #     grep: 'autoAttach'

    # Minify
    # ------
    uglify:
      options:
        mangle: false

      amd:
        files:
          'build/amd/chaplin.min.js': 'build/amd/chaplin.js'

      commonjs:
        files:
          'build/commonjs/chaplin.min.js': 'build/commonjs/chaplin.js'

      brunch:
        files:
          'build/brunch/chaplin.min.js': 'build/brunch/chaplin.js'

    # Compression
    # -----------
    compress:
      amd:
        files: [
          src: 'build/amd/chaplin.min.js'
          dest: 'build/amd/chaplin.min.js.gz'
        ]

      commonjs:
        files: [
          src: 'build/commonjs/chaplin.min.js'
          dest: 'build/commonjs/chaplin.min.js.gz'
        ]

      brunch:
        files: [
          src: 'build/brunch/chaplin.min.js'
          dest: 'build/brunch/chaplin.min.js.gz'
        ]

    # Watching for changes
    # --------------------
    watch:
      coffee:
        files: ['src/**/*.coffee']
        tasks: [
          'coffee:compile'
          'urequire'
          'copy:amd'
          'copy:test'
          'mocha'
        ]

      test:
        files: ['test/spec/*.coffee'],
        tasks: [
          'coffee:test'
          'mocha'
        ]

  # Events
  # ======
  grunt.event.on 'mocha.coverage', (coverage) ->
    # This is needed so the coverage reporter will find the coverage variable.
    global.__coverage__ = coverage

  # Dependencies
  # ============
  for name of pkg.devDependencies when name.substring(0, 6) is 'grunt-'
    grunt.loadNpmTasks name

  # Tasks
  # =====

  # Prepare
  # -------
  grunt.registerTask 'prepare', [
    'clean'
    'bower'
    'clean:components'
  ]

  # Build
  # -----
  grunt.registerTask 'build:commonjs', [
    'coffee:compile'
    'copy:commonjs'
    'concat:commonjs'
  ]

  grunt.registerTask 'build:amd', [
    'coffee:compile'
    'urequire'
    'copy:amd'
    'concat:amd'
  ]

  grunt.registerTask 'build:brunch', [
    'coffee:compile'
    'copy:commonjs'
    'concat:brunch'
  ]

  grunt.registerTask 'build:minified', [
    'uglify:commonjs'
    'compress:commonjs'
    'uglify:amd'
    'compress:amd'
    'uglify:brunch'
    'compress:brunch'
  ]

  grunt.registerTask 'build:all', [
    'build:amd'
    'build:commonjs'
    'build:brunch'
    'build:minified'
  ]

  grunt.registerTask 'build', [
    'build:amd'
    'build:commonjs'
    'build:brunch'
  ]

  # Lint
  # ----
  grunt.registerTask 'lint', 'coffeelint'

  # Test
  # ----
  grunt.registerTask 'test', [
    'coffee:compile'
    'urequire'
    'copy:amd'
    'copy:test'
    'coffee:test'
    'mocha'
  ]

  # Coverage
  # --------
  grunt.registerTask 'cover', [
    'coffee:compile'
    'urequire'
    'copy:amd'
    'copy:test'
    'coffee:test'
    'copy:beforeInstrument'
    'instrument'
    'mocha'
    'storeCoverage'
    'copy:afterInstrument'
    'makeReport'
  ]

  # Test Watcher
  # ------------
  grunt.registerTask 'test-watch', [
    'test'
    'watch'
  ]

  # Releasing
  # ---------

  grunt.registerTask 'check:versions:component', 'Check that package.json and component.json versions match', ->
    componentVersion = grunt.file.readJSON('component.json').version
    unless componentVersion is pkg.version
      grunt.fail.warn "component.json is version #{componentVersion}, package.json is #{pkg.version}."
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
    steps.push command(cmd: 'git', args: ['tag', '-a', pkg.version])

    grunt.util.async.waterfall steps, continuation

  grunt.registerTask 'release', [
    'check:versions',
    'release:git',
    'build',
    'build:minified',
    'transbrute:docs',
    'transbrute:downloads'
  ]

  # Publish Documentation
  # ---------------------
  grunt.registerTask 'docs:publish', ['check:versions:docs', 'transbrute:docs']

  # Default
  # -------
  grunt.registerTask 'default', [
    'lint'
    'clean'
    'build'
    'test'
  ]
