'use strict';

// Include gulp
var gulp = require('gulp');
var gulpSequence = require('gulp-sequence');
var sourcemaps = require('gulp-sourcemaps');
var coffee = require('gulp-coffee');
var gutil = require('gulp-util');
var del = require('del');

var scripts = ['src/**/*.coffee', 'src/**/*.js'];
var tests = ['test/**/*.coffee', 'test/**/*.js'];
var coverage = 'coverage/';
var mochaOpts = {
  require: ['./test/globals.js']
};
var coverageThresholds = {
  statements: 99.9,
  branches: 98.5,
  functions: 99.9,
  lines: 99.9
};

require('ot-gulp-release-tasks')(gulp, scripts, tests, mochaOpts, coverageThresholds);

gulp.task('default', ['ot-release-all']);

gulp.task('test', ['ot-release-coverage-test']);

gulp.task('test-all', gulpSequence('ot-release-no-coverage-test', 'ot-release-coverage-test'));

gulp.task('lint', ['ot-release-lint-coffee']);

gulp.task('clean:lib', function (cb) {
  del(['lib/**/*'], cb);
});

gulp.task('build:lib', ['clean:lib'], function () {
  gulp.src('./src/*.coffee')
    .pipe(sourcemaps.init())
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(sourcemaps.write())
    .pipe(gulp.dest('./lib/'));
});
