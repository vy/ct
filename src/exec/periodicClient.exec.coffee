# Parse command line arguments.
{argv} = require "optimist"
    .usage "Start the random cross-traffic client.\nUsage: $0"
    .demand "f"
    .alias "f", "serverAddressFile"
    .describe "f", "file containing list of server addresses in JSON"
    .alias "x", "excludedServerAddresses"
    .describe "x", "whitespace separated list of excluded server addresses"
    .default "x", ""
    .demand "c"
    .alias "c", "nConns"
    .describe "c", "number of concurrent connections"
    .demand "h"
    .alias "h", "hostId"
    .describe "h", "host id"
    .string "h"
    .demand "l"
    .alias "l", "lifetime"
    .describe "l", "flow lifetime"
    .demand "v"
    .alias "v", "lifetimeVariance"
    .describe "v", "variation window of the flow lifetime"

require("./helper").loadServerAddresses \
    argv.serverAddressFile, argv.excludedServerAddresses, (serverAddresses) ->
        {PeriodicClient} = require "../periodicClient"
        client = new PeriodicClient \
            serverAddresses, argv.nConns, argv.hostId, \
            argv.lifetime, argv.lifetimeVariance
        client.start()
        process.on "SIGINT", ->
            client.stop()
            process.exit()
