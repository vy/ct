net = require "net"

client = require "./client"
commons = require "./commons"
logger = require "./logger"
message = require "./message"


# Utility function to damp restart frequency of the `body`.
# @param [Integer] iniWaitPeriod initial wait period in milliseconds (must be non-zero)
# @param [Integer] maxWaitPeriod maximum restart frequency
# @param [Function] body function to be executed, takes a `restart` function parameter
restartDamper = (iniWaitPeriod, maxWaitPeriod, body) ->
    waitPeriod = iniWaitPeriod
    run = ->
        startTime = commons.getTime()
        body ->
            runPeriod = commons.getTime() - startTime
            waitPeriod = iniWaitPeriod if runPeriod > waitPeriod
            setTimeout run, waitPeriod
            waitPeriod = Math.min(maxWaitPeriod, waitPeriod * 2)
    run()


# Cross-traffic client implementation that generates periodic concurrent flows.
#
# `PeriodicClient` generates `connCount` concurrent connections to the given
# set of `serverAddresses`. Each flow has a random lifetime
# of `lifetime±lifetimeVariance`.
class exports.PeriodicClient extends client.Client

    # @property [logger.Logger] instance logger
    # @private
    _log: null

    # @property [Map<String,message.MessageProducer>] map of message producers keyed with `connId`
    # @private
    _producers: {}

    # @property [Array<String>] server addresses
    serverAddresses: null

    # @property [Integer] number of concurrent connections
    connCount: null

    # @param [netmask.Netmask] serverSubnet server network subnet
    # @param [Integer] serverCount number of servers
    # @param [Integer] connCount number of concurrent connections
    # @param [Integer] hostId host id
    # @param [Integer] lifetime flow lifetime in milliseconds
    # @param [Integer] lifetimeVariance variation window of the flow lifetime
    constructor: (@serverAddresses, @connCount, @hostId, @lifetime, @lifetimeVariance) ->
        @_log = new logger.Logger("PeriodicClient")
        @_log.setLevel("WARN")
        @_log.trace "Instantiated. " +
                    "(hostId=#{@hostId}, serverAddrs.length=#{@serverAddresses.length})"

    # Generates random flow lifetime using `lifetime` and `lifetimeVariance`.
    # @return [Integer] lifetime in milliseconds
    # @private
    _randLifetime: ->
        lo = @lifetime - @lifetimeVariance
        up = @lifetime + @lifetimeVariance
        commons.randInt(lo, up)

    # Initiates a new producer.
    # @private
    _startProducer: ->
        restartDamper 100, message.MessageProducer.timeoutPeriod, (restart) =>
            connId = PeriodicClient._createConnId()
            serverAddr = @serverAddresses[commons.randInt(0, @serverAddresses.length)]
            socket = new net.Socket()
            lifetime = @_randLifetime()
            @_producers[connId] = mp =
                new message.MessageProducer @hostId, connId, socket, lifetime, (err) =>
                    @_log.trace "[#{connId}] Stopped."
                    delete @_producers[connId]
                    if @_running
                        @_log.error "[#{connId}] Connection failure: #{err}" if err?
                        @_log.debug "[#{connId}] Connection expired." if mp.expired
                        restart()
            @_log.trace "[#{connId}] Connecting..."
            socket.connect commons.serverDataPort, serverAddr
            socket.on "connect", => @_log.trace "[#{connId}] Connected."

    # Starts message producers.
    start: ->
        @_running = true
        @_log.info "Starting..."
        @_startProducer() for _ in [1..@connCount]

    # Stops all active connections.
    stop: ->
        @_log.info "Stopping..."
        @_running = false
        mp.socket.end() for _, mp of @_producers
