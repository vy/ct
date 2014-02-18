MemoryStream = require "memorystream"

commons = require "../commons"
{Message, MessageConsumer, MessageProducer} = require "../message"


describe "message test suite", ->

    it "parameters should be preserved", ->
        [hostId, timestamp] = [1, 2]
        m = new Message hostId, timestamp
        expect(m.hostId).toBe(hostId)
        expect(m.timestamp).toBe(timestamp)

    it "same messages should be equal", ->
        a = new Message 1, 2
        b = new Message a.hostId, a.timestamp
        expect(a.equals b).toBe(true)

    it "timestamp field should be set correctly", ->
        m = new Message 1
        expect(m.timestamp).toBeCloseTo(commons.getTime(), -3)

    it "allocated buffer fields should match", ->
        a = new Message 1
        b = Message.fromBuffer(a.buffer)
        expect(a.equals(b)).toBe(true)


describe "input stream test suite", ->

    it "should parse a single message", (done) ->
        m = new Message 1
        parsed = false
        onMessage = (msg) ->
            expect(m.equals(msg)).toBe(true)
            parsed = true
        onEnd = (err) ->
            expect(parsed).toBe(true)
            expect(err?).toBe(false)
            done()
        ms = new MemoryStream()
        mc = new MessageConsumer "*", ms, onMessage, onEnd
        ms.write(m.buffer)
        ms.end()

    it "should parse partial data", (done) ->
        m = new Message 1
        parsed = false
        onMessage = (msg) ->
            expect(m.equals(msg)).toBe(true)
            parsed = true
        onEnd = (err) ->
            expect(parsed).toBe(true)
            expect(err?).toBe(false)
            done()
        ms = new MemoryStream()
        mc = new MessageConsumer "*", ms, onMessage, onEnd
        ms.write(m.buffer[...100])
        ms.write(m.buffer[100...])
        ms.end()

    _writeMessages = (done, writer) ->
        hostIds = commons.randArray(100, -> commons.randInt(1, 1000))
        messages = commons.toObject ([hostId, new Message hostId] for hostId in hostIds)
        retHostIds = []
        onMessage = (msg) ->
            expect(msg.hostId of messages).toBe(true)
            retHostIds.push msg.hostId
        onEnd = (err) ->
            expect(commons.buffer.equals(retHostIds, hostIds)).toBe(true)
            expect(err?).toBe(false)
            done()
        ms = new MemoryStream()
        mc = new MessageConsumer "*", ms, onMessage, onEnd
        writer(ms, messages)
        ms.end()

    it "should parse multiple messages", (done) ->
        _writeMessages done, (stream, messages) ->
            stream.write(message.buffer) for _, message of messages

    it "should parse multiple messages in a single batch", (done) ->
        _writeMessages done, (stream, messages) ->
            stream.write(Buffer.concat (message.buffer for _, message of messages))


describe "output stream test suite", ->

    it "should transmit a single message properly", (done) ->
        hostId = 0xDEAD
        received = false
        ms = new MemoryStream()
        ms.on "data", (data) ->
            msg = Message.fromBuffer data
            expect(msg.hostId).toBe(hostId)
            received = true
            ms.end()
        mp = new MessageProducer hostId, "*", ms, 6000, (err) ->
            expect(received).toBe(true)
            expect(err?).toBe(false)
            done()
        ms.emit "connect"

    it "should transmit multiple messages properly", (done) ->
        hostId = 0xDEAD
        nBytes = 0
        received = false
        n = 100
        ms = new MemoryStream()
        ms.on "data", (data) ->
            nBytes += data.length
            if nBytes is (n * Message.size)
                received = true
                ms.end()
        mp = new MessageProducer hostId, "*", ms, 6000, (err) ->
            expect(received).toBe(true)
            expect(err?).toBe(false)
            done()
        ms.emit "connect"

    it "should transmit during lifetime", (done) ->
        hostId = 0xDEAD
        ms = new MemoryStream()
        initTime = null
        lifetime = 1000
        ms.on "connect", -> initTime = commons.getTime()
        mp = new MessageProducer hostId, "*", ms, lifetime, (err) ->
            stopTime = commons.getTime()
            expect(stopTime - initTime).toBeCloseTo(lifetime, -1)
            done()
        ms.emit "connect"


describe "input and output stream test suite", ->

    it "should transceive a single message", (done) ->
        connId = "*"
        hostId = 0xDEAD
        received = false
        ms = new MemoryStream()
        onMessage = (msg) ->
            expect(msg.hostId).toBe(hostId)
            received = true
            ms.end()
        onConsumerEnd = (err) ->
            expect(received).toBe(true)
            expect(err?).toBe(false)
            done()
        mc = new MessageConsumer connId, ms, onMessage, onConsumerEnd
        mp = new MessageProducer hostId, connId, ms, 6000, (->)
        ms.emit "connect"

    it "should transceive multiple messages", (done) ->
        connId = "*"
        hostId = 0xBEEF
        nMsgs = 10
        nRecvMsgs = 0
        ms = new MemoryStream()
        onMessage = (msg) ->
            expect(msg.hostId).toBe(hostId)
            nRecvMsgs += 1
            ms.end() if nRecvMsgs is nMsgs
        onConsumerEnd = (err) ->
            expect(nRecvMsgs).toBe(nMsgs)
            expect(err?).toBe(false)
            done()
        mc = new MessageConsumer connId, ms, onMessage, onConsumerEnd
        mp = new MessageProducer hostId, connId, ms, 6000, (->)
        ms.emit "connect"
