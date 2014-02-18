commons = require "../commons"


describe "commons test suite", ->

    it "serverDataPort should be between 1024 and 63535", ->
        expect(1024 <= commons.serverDataPort <= 65535).toBe(true)

    it "MeanObserver should return 0 for no input", ->
        mo = new commons.MeanObserver()
        expect(mo.mean()).toBe(0)

    it "MeanObserver should return the correct mean", ->
        n = Math.floor(Math.random() * 100)
        samples = (Math.random() for _ in [1..n])
        sum = 0
        mo = new commons.MeanObserver()
        for sample in samples
            mo.update(sample)
            sum += sample
        mean = sum / n
        expect(mo.mean()).toBe(mean)

    it "ThroughputObserver should return 0 for no input", ->
        to = new commons.ThroughputObserver()
        expect(to.throughput()).toBe(0)

    it "ThroughputObserver should return the correct throughput", ->
        [sum, fts, lts] = [0, undefined, undefined]
        to = new commons.ThroughputObserver()
        while not fts? or (lts - fts) < 500
            ts = commons.getTime()
            sample = Math.random()
            to.update(sample)
            sum += sample
            fts ?= ts
            lts = ts
        tput = sum / (lts - fts)
        expect(to.throughput()).toBeCloseTo(tput, 0.001)

    it "buffer.equals(a,a) should return true", ->
        a = new Buffer("abc")
        expect(commons.buffer.equals(a, a)).toBe(true)

    _bufferEquals = (a, b, offset=0) ->
        xs = new Buffer(a)
        ys = new Buffer(b)
        commons.buffer.equals(xs, ys, offset)

    it "buffer.equals(a,b,-1) should throw exception", ->
        expect(-> _bufferEquals "", "", -1).toThrow()

    it "buffer.equals(a,b) should return false", ->
        expect(_bufferEquals "a", "b").toBe(false)

    it "buffer.equals(a,aa) should return false", ->
        expect(_bufferEquals "a", "aa").toBe(false)

    it "buffer.equals(aa,a) should return true", ->
        expect(_bufferEquals "aa", "a").toBe(true)

    it "buffer.equals(ab,b, 1) should return true", ->
        expect(_bufferEquals "aa", "a", 1).toBe(true)

    _bufferSearch = (a, b) ->
        xs = new Buffer(a)
        ys = new Buffer(b)
        commons.buffer.search(xs, ys)

    it "buffer.search(a,b) should return -1", ->
        expect(_bufferSearch "a", "b").toBe(-1)

    it "buffer.search(a,aa) should return -1", ->
        expect(_bufferSearch "a", "aa").toBe(-1)

    it "buffer.search(a,a) should return 0", ->
        expect(_bufferSearch "a", "a").toBe(0)

    it "buffer.search(ab,b) should return 0", ->
        expect(_bufferSearch "ab", "b").toBe(1)

    it "randInt(a,a) should return a", ->
        expect(commons.randInt 1, 1).toBe(1)

    it "randInt(2,1) should throw an exception", ->
        expect(-> commons.randInt(2, 1)).toThrow()

    it "randInt(a,b) should return integers in the range of [a,b)", ->
        xs = (commons.randInt(1, 5) for _ in [1..100])
        expect(xs.every (x) -> 1 <= x < 5).toBe(true)

    it "randArray(-1, *) should throw an exception", ->
        expect(-> commons.randArray -1, null).toThrow()

    it "randArray(0, *) should return []", ->
        expect(commons.randArray(0, null).length).toBe(0)

    it "randArray should have distinct items", ->
        for _ in [1..5]
            obj = {}
            len = commons.randInt(1, 100)
            arr = commons.randArray(len, -> commons.randInt(1, 1000))
            obj[key] = key for key in arr
            len-- for key of obj
            expect(len).toBe(0)

    it "randArray should preserve data types", ->
        expect(commons.randArray(1, -> commons.randInt(1, 1))[0]).toBe(1)

    it "toObject([]) should return {}", ->
        obj = commons.toObject([])
        len = 0
        len += 1 for key of obj
        expect(len).toBe(0)

    it "toObject should work as advertised", ->
        for _ in [1..5]
            orgObj = {}
            for _ in [1..100]
                val = commons.randInt(1, 100)
                key = "k#{val}"
                orgObj[key] = val
            pairs = ([key, val] for key, val of orgObj)
            newObj = commons.toObject pairs
            keys = (key for key of orgObj)
            expect(keys.every (key) -> newObj[key] = orgObj[key]).toBe(true)
