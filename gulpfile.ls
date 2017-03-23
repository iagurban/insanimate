require! {
  lodash: _
  path

  gulp
  
  'gulp-streamify'
  'gulp-uglify'
  'gulp-util'
  'gulp-if'
  'gulp-livescript'
  'gulp-changed'
  'gulp-debug'
  'gulp-rename'
  'gulp-connect'
  'gulp-plumber'

  browserify
  'browserify-shim'

  'vinyl-source-stream'
  'vinyl-buffer'
  'vinyl-transform'

  './package.json': packagejson
}

intermediate-path = "./.tmp"

tasks-manager = do ->
  with (
    add: ->
      @tasks.push it

    install: ->
      @tasks.map (.install!)
    task-names: -> @tasks.map (.task-name) .filter (?length)
    watch-task-names: -> @tasks.map (.watch-task-name) .filter (?length)
    )
      ..tasks = []

Base =
  install: ->
    gulp.task do
      @task-name
      (@deps?map (.task-name)) ? []
      (.bind @) @task
    
    gulp.task do
      @watch-task-name
      [@task-name]
      (.bind @) @watch-task

Livescript = (name, {i, o}:args) ->
  Object.assign do
    Object.create Base
    _.assign args,
      task-name: "ls:compile:#{name}"
      watch-task-name: "ls:watch:#{name}"
      
      task: ->
        gulp.src path.join @i, '**/*.ls'
        .pipe gulp-plumber!
        .pipe gulp-changed @o, extension: '.js' #, hasChanged: gulp-changed.compareSha1Digest
        .pipe gulp-debug title: 'Compiling ls:'
        .pipe gulp-livescript!
        .pipe gulp.dest @o
      
      watch-task: ->
        gulp.watch [path.join @i, '**/*.ls'], [@task-name]

post-bundle = (entry, o, name, debug, standalone, prebundle) ->
  basename = "#{name}#{unless debug => '.min' else ''}"
  filename = "#{basename}.js"
  
  prebundle browserify _.assign do
    debug: debug
    entries: [entry]
    {standalone} if standalone?
  .bundle!
  .pipe vinyl-source-stream filename
  .pipe vinyl-buffer!
  .pipe gulp-plumber!
  .pipe gulp-rename (<<< dirname: '.', basename: basename)
  .pipe gulp.dest o
  .pipe gulp-debug title: \bundled
  .pipe gulp-connect.reload!

Vendors = (name, {o}:args, externals) ->
  Object.assign do
    Object.create Base
    _.assign args,
      task-name: "js:bundle:#{name}"
      watch-task-name: "js:watch:#{name}"
      name: name
      externals: externals
      
      task: ->
        {o, name, externals} = @
        <- post-bundle './noop.js', o, name, false, null
        _.reduce externals, (-> &0.require &1), it
      watch-task: ->
        # gulp.watch [path.join @b, '**/*.js'], [@task-name]


Browserify = (name, {b, e, o}:args, deps, externals) ->
  Object.assign do
    Object.create Base
    _.assign args,
      task-name: "js:bundle:#{name}"
      watch-task-name: "ls:bundle:#{name}"
      name: name
      deps: deps
      externals: externals
      
      task: ->
        {o, b, e, name, externals} = @
        <- post-bundle (path.join b, e), o, name, (process.env.NODE_ENV != 'production'), name
        _.reduce externals, (-> &0.external &1), it
    
      watch-task: ->
        gulp.watch [path.join @b, '**/*.js'], [@task-name]

ls-folder = './demo/scripts'
tasks-manager.add do
  ls = Livescript do
    'demo'
    i: ls-folder
    o: path.join intermediate-path, ls-folder

tasks-manager.add do
  vendor = Vendors do
    'vendor'
    o: './dist'
    if packagejson.dependencies? => Object.keys that else []

tasks-manager.add do
  brwsrfy = Browserify do
    'demo'
    b: path.join intermediate-path, ls-folder
    e: 'app.js'
    o: './dist'
    [ls]
    if packagejson.dependencies? => Object.keys that else []

gulp.task \dev:server, ->
  gulp-connect.server do
    livereload: true
    port: 8000
    root: \./dist/

Copy = (name, {patterns, o}:args) ->
  Object.assign do
    Object.create Base
    {
      task-name: "copy:#{name}"
      watch-task-name: "watch:copy:#{name}"
      name
      patterns
      o
    }
    
    task: ->
      gulp.src @patterns
      .pipe gulp-changed @o
      .pipe gulp.dest @o
      .pipe gulp-connect.reload!
    
    watch-task: -> gulp.watch patterns, [@task-name]

tasks-manager.add do
  html = Copy do
    'html'
    patterns: ['./demo/views/index.html']
    o: './dist'

tasks-manager.install!
gulp.task \default, (tasks-manager.task-names! ++ tasks-manager.watch-task-names! ++ [\dev:server])

vinyl-browserify = (options) ->
  vinyl-transform (.bind null, options) (options, filename) ->
    options <<< entries: [filename]
    console.log filename, options
    browserify options
    |> ->
      # packagejson.dependencies.for-each it~external
      it.bundle!

# gulp.task 'default', <[t2]>

#->
  # create-standalone-build \insanimate, true, './scripts', 'index'
