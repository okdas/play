module.exports= (grunt) ->
    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        #clean:
        #    all: ['<%= pkg.config.build.app.node %>/']

        coffee:
            main:
                options:
                    bare: true
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.build.src.root %>'
                    src: ['**/*.coffee']
                    dest: '<%= pkg.config.build.app.root %>'
                    ext: '.js'
                }]

        yaml:
            package:
                options:
                    ignored: /^_/
                    space: 2
                files: [
                    {
                        expand: true
                        cwd: '<%= pkg.config.build.src.root %>'
                        src: ['**/*.yaml', '**/*.yml']
                        dest: '<%= pkg.config.build.app.root %>/'
                        ext: '.json'
                    }
                ]

        jade:
            compile:
                options:
                    data:
                        debug: false
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.build.src.node %>/views/public/templates'
                    src: ['**/*.jade']
                    dest: '<%= pkg.config.build.app.node %>/views/public/templates'
                    ext: '.html'
                }]

        copy:
            views:
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.build.src.node %>/views/public'
                    src: ['**/*', '!**/*.jade', '!**/*.coffee', '!**/*.md']
                    dest: '<%= pkg.config.build.app.node %>/views/public'
                }, {
                    expand: true
                    cwd: '<%= pkg.config.build.src.node %>/views/templates'
                    src: ['**/*', '!**/*.md']
                    dest: '<%= pkg.config.build.app.node %>/views/templates'
                }]

        #coffeelint:
        #    app:
        #        options:
        #            indentation:
        #                level: 'error'
        #                value: 4
        #            line_endings:
        #                value: 'unix'
        #                level: 'error'
        #            max_line_length:
        #                level: 'warn'
        #        files: [
        #            {
        #                src: '<%= pkg.config.build.src.root %>/**/*.coffee'
        #            }
        #        ]

        docco:
            debug:
                src: ['**/*.coffee'],
                options:
                    output: 'spec/docs/'




    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-yaml'
    #grunt.loadNpmTasks 'grunt-coffeelint'
    grunt.loadNpmTasks 'grunt-docco'

    grunt.registerTask 'default', ['yaml', 'coffee', 'jade', 'copy']
    #grunt.registerTask 'lint', ['coffeelint']
    grunt.registerTask 'doc', ['docco']
