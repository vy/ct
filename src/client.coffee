printf = require "printf"

commons = require "./commons"


class exports.Client

    # @property [Integer] host id
    hostId: null

    # @property [Boolean] running state flag
    # @private
    _running: false

    # Creates a (hopefully) unique connection id.
    # @return [String] connection id
    # @private
    @_createConnId: ->
        "#{commons.formatTime('YYYYMMDD-hhmmss.SSS')}-" +
        printf("%08X", commons.randInt(0, 0xFFFFFFFF))
