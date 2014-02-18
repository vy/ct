# Parse command line arguments.
{argv} = require "optimist"
    .usage "Start the cross-traffic server.\nUsage: $0"
    .demand "s"
    .alias "s", "serverSubnet"
    .describe "s", "server address subnet (e.g., 10.1.0.0/16)"
    .string "s"
    .demand "n"
    .alias "n", "nServers"
    .describe "n", "number of servers"
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
    .demand "t"
    .alias "t", "lifetimeThreshold"
    .describe "t", "variation window of the flow lifetime"

{Netmask} = require "netmask"
{Client} = require "../client"
serverSubnet = new Netmask argv.serverSubnet
client = new Client \
    serverSubnet, argv.nServers, argv.nConns, argv.hostId, \
    argv.lifetime, argv.lifetimeThreshold
client.start()
process.on "SIGINT", ->
    client.stop()
    process.exit()
