net = require "net"

{RandomClient} = require "../randomClient"
commons = require "../commons"


describe "random client test suite", ->

	it "should initiate a single connection", (done) ->
		serverAddr = "127.0.0.1"
		hostId = 0xDEAD
		client = new RandomClient [serverAddr], hostId
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
		hostId = 0xDEAD
		client = new RandomClient [serverAddr], 1, hostId
		server = net.createServer()
		server.on "error", -> done false
		server.listen commons.serverDataPort, serverAddr, 1, ->
			sockets = []
			server.on "connection", (socket) ->
				sockets.push socket
				if sockets.length > 1
					socket.destroy() for socket in sockets
					client.stop()
					server.close done
			client.start()
