gulp = require('gulp')
require('gulp-lazyload')
  connect:    'gulp-connect'
  concat:     'gulp-concat'
  coffee:     'gulp-coffee'
  preprocess: 'gulp-preprocess'
  iife:       'gulp-iife-wrap'
  uglify:     'gulp-uglify'
  rename:     'gulp-rename'
  del:        'del'
  plumber:    'gulp-plumber'

gulp.task 'default', ['build', 'watch'], ->

dependencies = [
  {global: 'Object', native: yes}
  {global: 'Error',  native: yes}
  {require: 'lodash'}
  {require: 'yess', global: '_'}
]

gulp.task 'build', ->
  gulp.src('source/__manifest__.coffee')
  .pipe plumber()
  .pipe preprocess()
  .pipe iife {dependencies, global: 'PropertyAccessors'}
  .pipe concat('property-accessors.coffee')
  .pipe gulp.dest('build')
  .pipe coffee()
  .pipe concat('property-accessors.js')
  .pipe gulp.dest('build')

gulp.task 'build-min', ['build'], ->
  gulp.src('build/property-accessors.js')
  .pipe uglify()
  .pipe rename('property-accessors.min.js')
  .pipe gulp.dest('build')

gulp.task 'watch', ->
  gulp.watch 'source/**/*', ['build']

gulp.task 'coffeespec', ->
  del.sync 'spec/**/*'
  gulp.src('coffeespec/**/*.coffee')
  .pipe coffee(bare: yes)
  .pipe gulp.dest('spec')
  gulp.src('coffeespec/support/jasmine.json')
  .pipe gulp.dest('spec/support')
