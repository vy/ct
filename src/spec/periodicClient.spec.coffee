net = require "net"
{Netmask} = require "netmask"

{PeriodicClient} = require "../periodicClient"
commons = require "../commons"


describe "client test suite", ->

	it "should initiate a single connection", (done) ->
		serverAddr = "127.0.0.1"
		connCount = 1
		hostId = 0xDEAD
		subnet = new Netmask "#{serverAddr}/32"
		client = new PeriodicClient subnet, 1, connCount, hostId, 10000, 0
		server = net.createServer()
		server.on "error", -> done false
		server.listen commons.serverDataPort, serverAddr, 1, ->
			server.on "connection", (socket) ->
				socket.end()
				client.stop()
				server.close done
			client.start()

	it "should initiate multiple connections", (done) ->
		serverAddr = "127.0.0.1"
		connCount = 10
		hostId = 0xDEAD
		subnet = new Netmask "#{serverAddr}/32"
		client = new PeriodicClient subnet, 1, connCount, hostId, 10000, 0
		server = net.createServer()
		server.on "error", -> done false
		server.listen commons.serverDataPort, serverAddr, 1, ->
			sockets = []
			server.on "connection", (socket) ->
				sockets.push socket
				if sockets.length is connCount
					socket.destroy() for socket in sockets
					client.stop()
					server.close done
			client.start()
