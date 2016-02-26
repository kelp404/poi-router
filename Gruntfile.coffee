module.exports = (grunt) ->
    require('time-grunt') grunt

    grunt.config.init
        coffee:
            build:
                files:
                    'dist/poi-router.js': [
                        'src/**/*.coffee'
                    ]

    grunt.registerTask 'build', [
        'coffee'
    ]

    # -----------------------------------
    # tasks
    # -----------------------------------
    grunt.loadNpmTasks 'grunt-contrib-coffee'
