bignum = require "bignum"

commons = require "./commons"
logger = require "./logger"


# Message container.
Message = class exports.Message

    # @property [Integer] message size (defaults 128KB)
    @size: 131072

    # @property [Buffer] message header
    @header: new Buffer("HELO")

    # @property [Integer] host id
    hostId: null

    # @property [Integer] send timestamp
    timestamp: null

    # @property [Buffer] message buffer
    buffer: null

    # @param [Integer] hostId host id
    # @param [Integer] timestamp timestamp, defaults to current time
    # @param [Buffer] message buffer, will be allocated if not specified
    constructor: (
        @hostId, @timestamp = commons.getTime(),
        @buffer = Message.toBuffer(@hostId, @timestamp)) ->

    # Allocates a new message buffer for the given parameters.
    @toBuffer: (hostId, timestamp) ->
        buffer = new Buffer(Message.size)
        Message.header.copy(buffer)
        offset = Message.header.length
        buffer.writeUInt32BE hostId, offset
        tsbuf = bignum(timestamp).toBuffer(size: 8)
        throw "invalid timestamp buffer" unless tsbuf.length is 8
        tsbuf.copy(buffer, offset + 4)
        buffer

    # Parses the given `buffer` and returns a new `Message`. 
    @fromBuffer: (buffer) ->
        throw "invalid buffer size" unless buffer.length is Message.size
        throw "invalid buffer header" unless commons.buffer.equals(buffer, Message.header)
        offset = Message.header.length
        hostId = buffer.readUInt32BE offset
        tsbuf = buffer[(offset+4)...(offset+12)]
        timestamp = bignum.fromBuffer(tsbuf, size: 8).toNumber()
        new Message hostId, timestamp, buffer

    # @nodoc
    toString: ->
        timestamp = commons.formatTime("YYYY-MM-DD hh:mm:ss.SSS", @timestamp)
        "Message[hostId=#{@hostId}, timestamp=#{timestamp}]"

    # Checks message equality.
    equals: (m) -> m? and m.hostId is @hostId and m.timestamp is @timestamp


# A wrapper for input stream sockets.
#
# `MessageConsumer` listens on the socket and tries to parse messages as data
# arrives. Upon receiving a complete message, it calls the `onMessage` callback.
# When socket ends (might be due to events `close`, `end`, `timeout`, and `error`)
# `onEnd` will be called.
class exports.MessageConsumer

    # @property [net.Socket] input stream socket
    socket: null

    # @property [String] connection identifier
    connId: null

    # @property [logger.Logger] instance logger
    # @private
    _log: null

    # @property [Buffer] received data waiting to be parsed
    # @private
    _buffer: new Buffer(0)

    # @property [Function] callback to be called upon receiving a message
    # @private
    _onMessage: null

    # @property [Function] callback to be called upon socket end
    # @private
    _onEnd: null

    constructor: (@connId, @socket, @_onMessage, @_onEnd) ->
        @_log = new logger.Logger @toString()
        @_log.setLevel("WARN")
        @socket.on "data", (data) => @_onData data
        @socket.on "end", => @_onEnd()
        @socket.on "timeout", => @_onTimeout()
        @socket.on "error", (err) => @_onError err

    # @nodoc
    # @private
    _onTimeout: ->
        @_log.debug "Socket timed out."
        # We are supposed to close the socket manually.
        @socket.end()

    # @nodoc
    # @private
    _onError: (error) ->
        @_log.debug "socket error: #{error}"
        # NodeJS will trigger a `close` event consequently, hence, we don't
        # need to call `onEnd` right now.

    # @nodoc
    # @private
    _onData: (data) ->
        @_log.trace "Received #{data.length} bytes."
        @_buffer = Buffer.concat [@_buffer, data]
        loop
            pos = commons.buffer.search @_buffer, Message.header
            end = pos + Message.size
            break if pos < 0 or end > @_buffer.length
            @_log.warn "Missed #{pos} bytes!" if pos > 0
            msg = Message.fromBuffer(@_buffer[pos...end])
            @_log.trace "Received message #{msg}."
            @_onMessage msg
            @_buffer = @_buffer[end..]
        # Avoid "loop" accumulate values returned within the loop.
        undefined

    # @nodoc
    toString: -> "MessageConsumer[#{@connId}]"


# A wrapper for output stream sockets.
#
# `MessageProducer` continuously transmits messages upon `socket` gets ready
# for write. `onShutdown` is called `end` is emitted.
MessageProducer = class exports.MessageProducer

    # @property [net.Socket] input stream socket
    socket: null

    # @property [String] connection identifier
    connId: null

    # @property [Integer] host id
    hostId: null

    # @property [Integer] flow life time in milliseconds
    lifetime: null

    # @property [Function] callback function to be called upon shutdown
    # @private
    onShutdown: null

    # @property [Boolean] turned on when the socket times out
    expired: false

    # @property [Boolean] enabled when socket is connected
    connected: false

    # @property [Integer] socket timeout period
    @timeoutPeriod: 5000

    # @property [logger.Logger] instance logger
    # @private
    _log: null

    constructor: (@hostId, @connId, @socket, @lifetime, @onShutdown) ->
        @_log = new logger.Logger @toString()
        @_log.setLevel("WARN")
        @socket.setTimeout?.apply MessageProducer.timeoutPeriod
        @socket.on "connect", => @_onConnect()
        @socket.on "end", => @_onEnd()
        @socket.on "timeout", => @_onTimeout()
        @socket.on "error", (err) => @_onError err
        setTimeout (=> @socket.end() if @connected), @lifetime

    # Called when socket is connected, initiates the transmission via `start`.
    # @private
    _onConnect: ->
        @_log.trace "Connected."
        @connected = true
        @start()

    # Called when socket is ended, invokes `onShutdown`.
    _onEnd: ->
        @_log.trace "Socket ended."
        @connected = false
        @onShutdown()

    # Called when socket is timed out, turns `expired` flag on and ends the socket.
    # @private
    _onTimeout: ->
        @_log.debug "Socket timed out."
        @expired = true
        @connected = false
        # We are supposed to close the socket manually.
        @socket.end()

    # @nodoc
    # @private
    _onError: (error) ->
        @_log.debug "Socket error: #{error}"
        if @connected
            # If connection is previously established, NodeJS will trigger a
            # `close` event consequently, hence, we don't need to call
            # `onEnd` right now.
            @connected = false
        else
            # Else, that is the connection could not be established, fall back
            # to shutdown immediatly.
            @onShutdown()

    # Continuosly transmits messages over the socket.
    # Should not be called directly, is triggered by `_onConnect`.
    start: ->
        if @connected
            msg = new Message(@hostId)
            @socket.write msg.buffer, =>
                @_log.trace "Transmitted #{msg}."
                setImmediate => @start()

    # @nodoc
    toString: -> "MessageProducer[#{@connId}]"
