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
    'temp/chaplin/lib/sync_machine.js'
    'temp/chaplin/lib/utils.js'
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
          dest: 'test/temp:original/'
          cwd: 'test/temp'
          src: '**/*.js'
        ]

      afterInstrument:
        files: [
          expand: true
          dest: 'test/temp/'
          cwd: 'test/temp:original'
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
        dest: 'build/amd/<%= pkg.name %>.js'
        src: modules

      commonjs:
        dest: 'build/commonjs/<%= pkg.name %>.js'
        src: modules

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
        src: [ 'test/index.html' ]

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

    # Compression
    # -----------
    compress:
      amd:
        files:
          'build/amd/chaplin.min.js.gz': 'build/amd/chaplin.min.js'

      commonjs:
        files:
          'build/commonjs/chaplin.min.js.gz': 'build/commonjs/chaplin.min.js'

    # Filesize
    # --------
    filesize:
      build:
        files: 'build/**/*'

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
  grunt.event.on 'mocha.done', (failed, passed, total, time, coverage) ->
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
    'uglify:commonjs'
    'compress:commonjs'
  ]

  grunt.registerTask 'build:amd', [
    'coffee:compile'
    'urequire'
    'copy:amd'
    'concat:amd'
    'uglify:amd'
    'compress:amd'
  ]

  grunt.registerTask 'build', [
    'build:amd'
    'build:commonjs'
    'filesize'
  ]

  # Lint
  # ----
  grunt.registerTask 'lint', 'coffeelint'

  # Test
  # ----
  grunt.registerTask 'test', [
    'prepare'
    'build:amd'
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
    'coffee:compile'
    'urequire'
    'copy:amd'
    'copy:test'
    'coffee:test'
    'mocha'
    'watch'
  ]

  # Default
  # -------
  grunt.registerTask 'default', [
    'lint'
    'clean'
    'build'
    'test'
  ]
