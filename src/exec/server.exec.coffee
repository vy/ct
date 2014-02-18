# Parse command line arguments.
{argv} = require "optimist"
    .usage "Start the cross-traffic server.\nUsage: $0"
    .demand "f"
    .alias "f", "reportFile"
    .describe "f", "report output file"
    .string "f"

# Start the server.
{Server} = require "../server"
server = new Server()
server.start()
process.on "SIGINT", -> server.report argv.f, ->
    server.stop()
    process.exit()
