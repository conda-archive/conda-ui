var gulp = require('gulp');
var mocha = require('gulp-mocha');
var gutil = require('gulp-util');
var coffee = require('gulp-coffee');
var browserify = require('browserify')
var source = require('vinyl-source-stream')
var paths = {
  'coffee': {
    'src': './conda_ui/static/conda_ui/conda.coffee',
    'dest_filename': 'application.js',
    'dest_path':'./conda_ui/static/conda_ui/'
  }
}

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

gulp.task('scripts', function() {
  browserify({
    'entries': paths.coffee.src,
    'extensions': ['.coffee',],
    'paths': ['conda_ui/static/conda_ui',],
  }).transform('coffeeify')
  .bundle()
  .pipe(source(paths.coffee.dest_filename))
  .pipe(gulp.dest(paths.coffee.dest_path))

});
