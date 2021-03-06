moment = require "moment"


# Returns current time in milliseconds.
# @return [Integer] time in milliseconds
exports.getTime = -> new Date().getTime()


# Formats given epoch.
# @return [String] formatted time
exports.formatTime = (format, time = exports.getTime()) -> moment(time).format(format)


# Server data port.
exports.serverDataPort = 7000


# Observes the mean on a given set of samples.
class exports.MeanObserver

    # @property [Integer] available sample count
    len: 0

    # @property [Number] sum of the collected samples
    sum: 0

    # Updates the mean using the given `sample`.
    update: (sample) ->
        @sum += sample
        @len += 1

    # Returns the mean of the collected samples.
    # @return [Number] recent mean
    mean: -> if @len then (@sum / @len) else 0

    # @nodoc
    toString: -> "MeanObserver[#{@len} samples]"


# Observes the throughput over provided samples.
# Throughput is calculated by dividing the sum of the samples to the time period
# between the first and the last sample.
class exports.ThroughputObserver

    # @property [Number] sum of the collected samples
    # @private
    sum: 0

    # @property [Number] timestamp of the first sample
    # @private
    fts: null

    # @property [Number] timestamp of the last sample
    # @private
    lts: null

    # Updates the throughput using the given `sample`.
    update: (sample) ->
        @sum += sample
        @lts = exports.getTime()
        @fts ?= @lts

    # Returns the throughput of the collected samples.
    # @return [Number] recent throughput
    throughput: ->
        duration = @lts - @fts
        if duration then (@sum / duration) else 0

    # @nodoc
    toString: -> "ThroughputObserver[#{@lts - @fts} ms]"


exports.buffer =

    # Checks if `xs` starting from index `offset` overlaps with `ys`.
    # @return [Boolean] Returns true if it overlaps, false otherwise.
    equals: (xs, ys, offset=0) ->
        throw "offset cannot be negative" unless offset >= 0
        return false unless xs.length - offset >= ys.length
        for i in [0...ys.length]
            unless xs[i+offset] is ys[i]
                return false
        return true

    # Searches `ys` in `xs`.
    # @return [Integer] Returns the index of the found position, -1 otherwise.
    search: (xs, ys) ->
        nxs = xs.length
        nys = ys.length
        if nxs >= nys
            for i in [0..(nxs-nys)]
                if exports.buffer.equals(xs, ys, i)
                    return i
        return -1


# Generate a random integer within the given range.
# @param [Integer] lo lower bound, inclusive
# @param [Integer] up upper bound, exclusive
# @return [Integer] random integer
exports.randInt = (lo, up) ->
    throw "invalid range" unless lo <= up
    lo + Math.floor((up-lo) * Math.random())


# Creates an array of non-overlapping items generated by given `random` function.
# @param [Integer] array size
# @param [Function] random item generator
# @return [Array<T>] random array
exports.randArray = (n, random) ->
    throw "invalid array size" unless n >= 0
    obj = {}
    len = 0
    while len < n
        key = random()
        unless key of obj
            obj[key] = key
            len++
    (val for _, val of obj)

# Creates an object using the given list of `[key, value]` pairs.
# @return [Object] built object
exports.toObject = (pairs) ->
    obj = {}
    obj[key] = value for [key, value] in pairs
    obj


# Returns `true` if the given `address` is a valid IPv4 address, `false` otherwise.
exports.isValidIPv4Address = (address) ->
    address.match(///\b
        (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
        (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
        (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.
        (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)
        \b///)?
