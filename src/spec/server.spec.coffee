net = require "net"

commons = require "../commons"
message = require "../message"
server = require "../server"


describe "server test suite", ->

    _server = undefined

    beforeEach ->
        _server = new server.Server()
        _server.start()

    afterEach -> _server.stop()

    _connect = (onConnect) -> net.connect commons.serverDataPort, onConnect

    _consumerCount = -> (connId for connId of _server._consumers).length

    it "server should accept connections", (done) ->
        expect(_consumerCount()).toBe(0)
        socket = _connect ->
            expect(_consumerCount()).toBe(1)
            expect(_server._connTput.sum).toBe(1)
            socket.end()
        socket.on "close", (err) ->
            expect(err).toBe(false)
            expect(_consumerCount()).toBe(0)
            done()

    it "server should consume a single message", (done) ->
        expect(_consumerCount()).toBe(0)
        msg = new message.Message 1
        checkServer = ->
            expect(_server._dataTput.sum).toBe(message.Message.size)
            expect(_server._dataLtnc.sum).toBeGreaterThan(0)
            expect(msg.hostId of _server._hostDataTput).toBe(true)
            expect(msg.hostId of _server._hostDataLtnc).toBe(true)
            done()
        socket = _connect ->
            expect(_consumerCount()).toBe(1)
            socket.write msg.buffer, ->
                socket.end()
                setTimeout(checkServer, 100)
