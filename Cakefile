{print} = require "sys"
{spawn} = require "child_process"


_SRC_DIR = "src"
_OUT_DIR = "out"


_out = (file) -> "#{_OUT_DIR}/#{file}"
_bin = (file) -> "./node_modules/.bin/#{file}"


_spawnProcess = (file, args) ->
    proc = spawn file, args
    proc.stderr.on "data", (data) -> process.stderr.write data.toString()
    proc.stdout.on "data", (data) -> process.stdout.write data.toString()


compile = (watch) ->
    args = ["-c", "-o", _OUT_DIR, _SRC_DIR]
    args = ["-w"].concat(args) if watch?
    _spawnProcess _bin("coffee"), args

task "compile", "Compile CoffeeScript sources in '#{_SRC_DIR}' to '#{_OUT_DIR}'", compile

task "watch", "Watch '#{_SRC_DIR}' for changes", -> compile(true)


doc = -> _spawnProcess _bin("codo"), [_SRC_DIR]

task "doc", "Create the documentation from sources", doc


test = ->
	_spawnProcess \
		_bin("jasmine-node"),
		["--verbose", "--forceexit", "--captureExceptions", _out("spec")]

task "test", "Run test suites", test
