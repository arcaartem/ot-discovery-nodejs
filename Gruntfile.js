module.exports = function(grunt) {
    'use strict';

    grunt.initConfig({
        jshint: {
            all: [ '*.js' ]
        }
    });

    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.registerTask('default', ['jshint', 'start-server']);
    grunt.loadTasks('./tests/tasks/');
};
