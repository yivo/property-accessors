gulp       = require('gulp')
concat     = require('gulp-concat')
coffee     = require('gulp-coffee')
preprocess = require('gulp-preprocess')
umd        = require('gulp-umd-wrap')
del        = require('del')
plumber    = require('gulp-plumber')
fs         = require('fs')

gulp.task 'default', ['build', 'watch'], ->

gulp.task 'build', ->
  gulp.src('source/__manifest__.coffee')
    .pipe plumber()
    .pipe preprocess()
    .pipe umd do ->
                global: 'PropertyAccessors'
                dependencies: [
                  {global: 'Object',    native:  true}
                  {global: 'Error',     native:  true}
                  {global: 'TypeError', native:  true}
                  {global: '_',         require: 'lodash'}]
                header: fs.readFileSync('source/__license__.coffee')
    .pipe concat('property-accessors.coffee')
    .pipe gulp.dest('build')
    .pipe coffee()
    .pipe concat('property-accessors.js')
    .pipe gulp.dest('build')

gulp.task 'watch', ->
  gulp.watch 'source/**/*', ['build']

gulp.task 'coffeespec', ->
  del.sync 'spec/**/*'
  gulp.src('coffeespec/**/*.coffee')
    .pipe coffee(bare: true)
    .pipe gulp.dest('spec')
  gulp.src('coffeespec/support/jasmine.json')
    .pipe gulp.dest('spec/support')
