# Parse command line arguments.
{argv} = require "optimist"
    .usage "Start the random cross-traffic client.\nUsage: $0"
    .demand "s"
    .alias "s", "serverSubnet"
    .describe "s", "server address subnet (e.g., 10.1.0.0/16)"
    .string "s"
    .demand "n"
    .alias "n", "nServers"
    .describe "n", "number of servers"
    .demand "h"
    .alias "h", "hostId"
    .describe "h", "host id"
    .string "h"

{Netmask} = require "netmask"
{RandomClient} = require "../randomClient"
serverSubnet = new Netmask argv.serverSubnet
client = new RandomClient serverSubnet, argv.nServers, argv.hostId
client.start()
process.on "SIGINT", ->
    client.stop()
    process.exit()
