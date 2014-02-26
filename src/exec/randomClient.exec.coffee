# Parse command line arguments.
{argv} = require "optimist"
    .usage "Start the random cross-traffic client.\nUsage: $0"
    .demand "f"
    .alias "f", "serverAddressFile"
    .describe "f", "file containing list of server addresses in JSON"
    .string "f"
    .demand "h"
    .alias "h", "hostId"
    .describe "h", "host id"
    .string "h"


require("fs").readFile argv.serverAddressFile, (err, data) ->
    throw "Failed opening '#{serverAddressFile}': #{err}" if err?
    serverAddresses = JSON.parse(data)
    {isValidIPv4Address} = require "../commons"
    for serverAddress in serverAddresses
        unless isValidIPv4Address serverAddress
            throw "Invalid IPv4 address: #{serverAddress}"

    {RandomClient} = require "../randomClient"
    client = new RandomClient serverAddresses, argv.hostId
    client.start()
    process.on "SIGINT", ->
        client.stop()
        process.exit()
