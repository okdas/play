module.exports= (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        clean:
            all: ['<%= pkg.config.app.node %>/']

        coffee:
            main:
                options:
                    bare: true
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.src.root %>'
                    src: ['**/*.coffee']
                    dest: '<%= pkg.config.app.root %>'
                    ext: '.js'
                }]

        yaml:
            package:
                options:
                    ignored: /^_/
                    space: 2
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.src.root %>'
                    src: ['**/*.yaml', '**/*.yml', '!**/views/**']
                    dest: '<%= pkg.config.app.root %>/'
                    ext: '.json'
                }]

        jade:
            compile:
                options:
                    data:
                        debug: false
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.src.views.templates.cwd %>'
                    src: ['**/*.jade', '!**/layout.jade']
                    dest: '<%= pkg.config.app.views.templates.cwd %>'
                    ext: '.html'
                }]

        less:
            compile:
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.src.views.assets.cwd %>/styles'
                    src: ['**/*.less']
                    dest: '<%= pkg.config.app.views.assets.cwd %>/styles'
                    ext: '.css'
                }]

        copy:
            views:
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.src.views.assets.cwd %>'
                    src: ['**/*', '!**/components/**', '!**/*.less', '!**/*.jade', '!**/*.coffee', '!**/*.md']
                    dest: '<%= pkg.config.app.views.assets.cwd %>'
                }, {
                    expand: true
                    cwd: '<%= pkg.config.src.views.assets.cwd %>/components/font-awesome/font'
                    src: ['**/*']
                    dest: '<%= pkg.config.app.views.assets.cwd %>/fonts/awesome'
                }]
            sql:
                files: [{
                    expand: true
                    cwd: '<%= pkg.config.src.node %>/db/sql'
                    src: ['**/*.sql']
                    dest: '<%= pkg.config.app.node %>/db/sql'
                }]

        docco:
            debug:
                src: ['**/*.coffee'],
                options:
                    output: 'spec/docs/'

        watch:
            jade:
                files: ['**/*.jade', '**/*.coffee']
                tasks: ['jade']
                options:
                    cwd: '<%= pkg.config.src.views.templates.cwd %>'
            less:
                files: ['**/*.less']
                tasks: ['less']
                options:
                    cwd: '<%= pkg.config.src.views.assets.cwd %>'

    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-yaml'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-docco'

    grunt.registerTask 'default', ['clean', 'yaml', 'coffee', 'jade', 'less', 'copy']
    grunt.registerTask 'dev', ['watch']
    grunt.registerTask 'doc', ['docco']
