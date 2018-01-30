path = require 'path'


module.exports = (grunt) ->
    require('time-grunt') grunt

    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-karma'
    grunt.loadNpmTasks 'grunt-parallel'

    grunt.config.init
        coffee:
            build:
                files:
                    'dist/poi-router.js': [
                        'src/**/*.coffee'
                    ]
            example:
                expand: yes
                flatten: no
                cwd: 'example'
                src: [
                    '**/*.coffee'
                ]
                dest: 'example'
                ext: '.js'
        watch:
            example:
                files: [
                    'example/**/*.coffee'
                ]
                tasks: ['coffee:example']
                options:
                    spawn: no
        parallel:
            develop:
                tasks: [
                    {
                        grunt: yes
                        stream: yes
                        args: ['watch']
                    }
                    {
                        # run example server
                        stream: yes
                        cmd: 'node'
                        args: [path.resolve('example', 'server.js')]
                    }
                ]
        karma:
            testFrontend:
                configFile: 'test/karma.config.coffee'

    grunt.registerTask 'build', [
        'coffee:build'
    ]
    grunt.registerTask 'default', [
        'parallel:develop'
    ]
