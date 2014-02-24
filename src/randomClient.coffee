net = require "net"

client = require "./client"
commons = require "./commons"
logger = require "./logger"
message = require "./message"


# Cross-traffic client implementation that generates random flows.
#
# `RandomClient` generates temporary flows to the specified set of servers.
# Flow inter-arrival time is set to be exponentially distributed and flow
# lifetimes are picked randomly from the range [0, 10).
#
# In order to avoid port exhaustion due to `TIME-WAIT` sockets, you should
# enable TCP time-wait socket recycling (that is, `net.ipv4.tcp_tw_recycle`) in
# the kernel.
class exports.RandomClient extends client.Client

    # @property [logger.Logger] instance logger
    # @private
    _log: null

    # @property [Boolean] hotspot flag
    hotspot: false

    # @property [Integer] hotspot flag toggle period (in milliseconds)
    @hotspotTogglePeriod: 10000

    # @property [Float] ratio of the hotspot flows
    # @private
    @hotspotRatio: 0.3

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

    # @param [netmask.Netmask] serverSubnet server network subnet
    # @param [Integer] serverCount number of servers
    # @param [Integer] hostId host id
    constructor: (@serverSubnet, @serverCount, @hostId) ->
        @_log = new logger.Logger("RandomClient")
        @_log.setLevel("WARN")
        addrs = []
        @serverSubnet.forEach (addr) -> addrs.push addr
        @_serverAddrs = addrs[...@serverCount]
        @_log.trace "Instantiated. " +
                    "(hostId=#{@hostId}, serverAddrs.length=#{@_serverAddrs.length})"

    # Generates random flow lifetime using U[0, 10).
    # @private
    @_randomFlowLifetime: ->
        coeff = if @hotspot then 2 else 1
        coeff * Math.random() * 10

    # Generates random flow inter-arrival time via exponential distribution.
    # @private
    @_randomFlowInterArrivalTime: -> -Math.log(1 - Math.random())

    # Initiates a new producer.
    # @private
    _startProducer: ->
        connId = RandomClient._createConnId()
        socket = new net.Socket()
        lifetime = RandomClient._randomFlowLifetime()
        @_producers[connId] = mp =
            new message.MessageProducer @hostId, connId, socket, lifetime, (err) =>
                @_log.trace "[#{connId}] Stopped."
                delete @_producers[connId]
                if @_running
                    @_log.error "[#{connId}] Connection failure: #{err}" if err?
                    @_log.debug "[#{connId}] Connection expired." if mp.expired
        @_log.trace "[#{connId}] Connecting..."
        serverAddr = @_serverAddrs[commons.randInt(0, @_serverAddrs.length)]
        socket.connect commons.serverDataPort, serverAddr
        socket.on "connect", => @_log.trace "[#{connId}] Connected."
        setTimeout (=> @_startProducer()), RandomClient._randomFlowInterArrivalTime() if @_running

    # Toggles hotspot ratio every `hotspotTogglePeriod` seconds, while `_running`.
    _toggleHotspot: ->
        if Math.random() > RandomClient.hotspotRatio
            @hotspot = !@hotspot
            @_log.trace "Set hotspot to #{@hotspot}."
        setTimeout (=> @_toggleHotspot()), RandomClient.hotspotTogglePeriod if @_running

    # Starts message producers.
    start: ->
        @_running = true
        @_log.info "Starting..."
        @_toggleHotspot()
        @_startProducer()

    # Stops all active connections.
    stop: ->
        @_log.info "Stopping..."
        @_running = false
        mp.socket.end() for _, mp of @_producers
