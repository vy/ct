printf = require "printf"
net = require "net"

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


class exports.Client

    # @property [logger.Logger] instance logger
    # @private
    _log: null

    # @property [Map<String,message.MessageProducer>] map of message producers keyed with `connId`
    # @private
    _producers: {}

    # @property [netmask.Netmask] server network subnet
    serverSubnet: null

    # @property [Integer] number of servers
    serverCount: null

    # @property [Array<String>] server addresses
    # @private
    _serverAddrs: null

    # @property [Integer] number of concurrent connections
    connCount: null

    # @property [Integer] host id
    hostId: null

    # @property [Boolean] running state flag
    # @private
    _running: false

    # @param [netmask.Netmask] serverSubnet server network subnet
    # @param [Integer] serverCount number of servers
    # @param [Integer] connCount number of concurrent connections
    # @param [Integer] hostId host id
    # @param [Integer] lifetime flow lifetime in milliseconds
    # @param [Integer] lifetimeThreshold variation window of the flow lifetime
    constructor: (@serverSubnet, @serverCount, @connCount, @hostId, @lifetime, @lifetimeThreshold) ->
        @_log = new logger.Logger("Client")
        @_log.setLevel("WARN")
        addrs = []
        @serverSubnet.forEach (addr) -> addrs.push addr
        @_serverAddrs = addrs[...@serverCount]
        @_log.trace "Instantiated. " +
                    "(hostId=#{@hostId}, serverAddrs.length=#{@_serverAddrs.length})"

    # Creates a (hopefully) unique connection id.
    # @return [String] connection id
    # @private
    @_createConnId: ->
        "#{commons.formatTime('YYYYMMDD-hhmmss.SSS')}-" +
        printf("%08X", commons.randInt(0, 0xFFFFFFFF))

    # Generates random flow lifetime using `lifetime` and `lifetimeThreshold`.
    # @return [Integer] lifetime in milliseconds
    # @private
    _randLifetime: ->
        lo = @lifetime - @lifetimeThreshold
        up = @lifetime + @lifetimeThreshold
        commons.randInt(lo, up)

    # Initiates a new producer.
    # @private
    _startProducer: ->
        restartDamper 100, message.MessageProducer.timeoutPeriod, (restart) =>
            connId = Client._createConnId()
            serverAddr = @_serverAddrs[commons.randInt(0, @_serverAddrs.length)]
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
