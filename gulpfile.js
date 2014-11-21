var gulp = require('gulp');
var mocha = require('gulp-mocha');
var gutil = require('gulp-util');
var coffee = require('gulp-coffee');

gulp.task('mocha', function() {
  return gulp.src(['test/*.js'], {read: false})
    .pipe(mocha({reporter: 'list'}))
    .on('error', gutil.log);
});
gulp.task('watch-mocha', function() {
  gulp.watch(['test/**', 'conda_ui/static/conda_ui/*.js', 'conda_ui/static/conda-js/conda.js'], ['mocha']);
});
gulp.task('coffee', function() {
  return gulp.src(['conda_ui/static/conda_ui/*.coffee',])
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(gulp.dest('./conda_ui/static/conda_ui/'))
});
gulp.task('watch-coffee', function() {
  gulp.watch(['conda_ui/static/conda_ui/*.coffee'], ['coffee']);
});
gulp.task('watch', ['watch-mocha', 'watch-coffee'])
