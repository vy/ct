# Parse command line arguments.
{argv} = require "optimist"
    .usage "Start the random cross-traffic client.\nUsage: $0"
    .demand "f"
    .alias "f", "serverAddressFile"
    .describe "f", "file containing list of server addresses in JSON"
    .string "f"
    .alias "x", "excludedServerAddresses"
    .describe "x", "whitespace separated list of excluded server addresses"
    .default "x", ""
    .demand "h"
    .alias "h", "hostId"
    .describe "h", "host id"
    .string "h"

require("./helper").loadServerAddresses \
    argv.serverAddressFile, argv.excludedServerAddresses, (serverAddresses) ->
        {RandomClient} = require "../randomClient"
        client = new RandomClient serverAddresses, argv.hostId
        client.start()
        process.on "SIGINT", ->
            client.stop()
            process.exit()
