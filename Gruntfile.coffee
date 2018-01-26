module.exports = (grunt) ->
    require('time-grunt') grunt

    grunt.config.init
        coffee:
            build:
                files:
                    'dist/poi-router.js': [
                        'src/**/*.coffee'
                    ]
        karma:
            testFrontend:
                configFile: 'test/karma.config.coffee'

    grunt.registerTask 'build', [
        'coffee'
    ]

    # -----------------------------------
    # tasks
    # -----------------------------------
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-karma'
