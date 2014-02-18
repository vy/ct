fs = require "fs"
net = require "net"

commons = require "./commons"
logger = require "./logger"
message = require "./message"


# Cross-traffic receiver server.
class exports.Server

    # @property [logger.Logger] instance logger
    # @private
    _log: null

    # @property [net.Server] active server instance
    # @private
    _server: null

    # @property [Map<String,message.MessageConsumer>] message consumers keyed with `iden`
    # @private
    _consumers: {}

    # @property [Map<Integer,commons.MeanObserver>] host data throughputs keyed with `hostId`
    # @private
    _hostDataTput: {}

    # @property [Map<Integer,commons.MeanObserver>] host data latencies keyed with `hostId`
    # @private
    _hostDataLtnc: {}

    # @property [commons.ThroughputObserver] data throughput
    # @private
    _dataTput: new commons.ThroughputObserver()

    # @property [commons.MeanObserver] data latency
    # @private
    _dataLtnc: new commons.MeanObserver()

    # @property [commons.ThroughputObserver] accepted connection throughput
    # @private
    _connTput: new commons.ThroughputObserver()

    # @property [Map<String,Integer>] `connId` to `hostId` map
    # @private
    _connHostIds: {}

    # @property [Map<String,commons.ThroughputObserver>] per connection data throughput observers
    # @private
    _connDataTput: {}

    constructor: () ->
        @_log = new logger.Logger("Server")
        @_log.setLevel("WARN")

    # Updates statistics for the given received message.
    # @private
    _consumeMessage: (connId, msg) ->
        @_log.trace "Received message #{msg}."
        latency = commons.getTime() - msg.timestamp
        hostId = msg.hostId
        @_connHostIds[connId] ?= hostId
        # Update connection data throughput statistics.
        @_connDataTput[connId] ?= new commons.ThroughputObserver()
        @_connDataTput[connId].update message.Message.size
        # Update host latency statistics.
        @_hostDataLtnc[hostId] ?= new commons.MeanObserver()
        @_hostDataLtnc[hostId].update(latency)
        # Update global statistics.
        @_dataTput.update message.Message.size
        @_dataLtnc.update latency

    # Removes related data structure entries for the given connection.
    # @private
    _removeConn: (connId, error) ->
        @_log.error("Connection #{connId} failure: #{error}") if error?
        @_log.debug "Removing connection #{connId}..."
        hostId = @_connHostIds[connId]
        throughput = @_connDataTput[connId].throughput()
        @_hostDataTput[hostId] ?= new commons.MeanObserver()
        @_hostDataTput[hostId].update throughput
        delete @_connDataTput[connId]
        delete @_connHostIds[connId]
        delete @_consumers[connId]

    # Creates a connection id for the given `socket`.
    # @private
    @_createConnId: (socket) ->
        "#{commons.formatTime('YYYYMMDD-hhmmss.SSS')}-" +
        "#{socket.remoteAddress}:#{socket.remotePort}"

    # Registers a `MessageConsumer` for the given socket.
    # @private
    _acceptConn: (socket) ->
        @_connTput.update(1)
        connId = Server._createConnId socket
        @_log.debug "Accepted connection #{connId}."
        onMessage = (message) => @_consumeMessage connId, message
        onEnd = (error) => @_removeConn connId, error
        @_consumers[connId] = new message.MessageConsumer connId, socket, onMessage, onEnd

    # Starts the server on `commons.serverDataPort`.
    start: ->
        @_log.trace "Starting the server..."
        @_server = net.createServer (socket) => @_acceptConn socket
        @_server.listen commons.serverDataPort, =>
            @_log.info "Started listening on #{commons.serverDataPort}."

    # Stops the server.
    stop: ->
        @_log.trace "Stopping the server..."
        consumer.socket.end() for _, consumer of @_consumers
        @_server.close(=> @_log.info "Stopped the server.") if @_server?

    # Reports the current statistics.
    report: (outFile, callback) ->
        @_log.info "Reporting statistics to #{outFile}..."
        out = ""
        out += "data throughput to host #{hostId}: #{obs.mean()} bytes/ms\n" for hostId, obs of @_hostDataTput
        out += "data latency to host #{hostId}: #{obs.mean()} ms\n" for hostId, obs of @_hostDataLtnc
        out += "total data throughput: #{@_dataTput.throughput()} bytes/ms\n"
        out += "total data latency: #{@_dataLtnc.mean()} ms\n"
        out += "total connection throughput: #{@_connTput.throughput()} conns/ms\n"
        fs.writeFile outFile, out, (err) =>
            @_log.error "Failed writing to file: #{err}" if err?
            callback?()
