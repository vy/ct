log4js = require "log4js"


# A logger wrapper over log4js.
class exports.Logger

    # @property [log4js.Logger] logger instance
    # @private
    _logger: null

    # @property [String] logger name
    # @private
    _name: null

    # @property [String] log level (defaults to "INFO")
    # @private
    _level: "INFO"

    # @param [String] name the logger name
    constructor: (@_name) ->
        @_logger = log4js.getLogger(@_name)
        @_logger.setLevel(@_level)

    # logger name getter
    # @return [String] logger name
    getName: -> @_name

    # log level getter
    # @return [String] log level
    getLevel: -> @_level

    # log level setter
    setLevel: (level) ->
        @_logger.setLevel(level)
        @_level = level

    # @nodoc
    trace: (s) -> @_logger.trace(s)

    # @nodoc
    debug: (s) -> @_logger.debug(s)

    # @nodoc
    info: (s) -> @_logger.info(s)

    # @nodoc
    warn: (s) -> @_logger.warn(s)

    # @nodoc
    error: (s) -> @_logger.error(s)

    # @nodoc
    fatal: (s) -> @_logger.fatal(s)

    # @nodoc
    toString: -> "Logger[#{@_name}]"
