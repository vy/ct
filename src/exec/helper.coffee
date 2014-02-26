fs = require "fs"

commons = require "../commons"


exports.loadServerAddresses = (serverAddressFile, excludedServerAddresses, callback) ->
	fs.readFile serverAddressFile, (err, data) ->
	    throw "Failed opening '#{serverAddressFile}': #{err}" if err?
	    serverAddresses = JSON.parse(data)

	    # Collect excluded server addresses.
	    excludedServerAddresses = commons.toObject \
	        ([serverAddress.trim(), true] \
	            for serverAddress in excludedServerAddresses.split /\s+/)

	    # Validate and collect server addresses.
	    validServerAddresses = []
	    for serverAddress in serverAddresses
	        if serverAddress not of excludedServerAddresses
	            unless commons.isValidIPv4Address serverAddress
	                throw "Invalid IPv4 address: #{serverAddress}"
	            validServerAddresses.push serverAddress

	    # Continue execution.
	    callback validServerAddresses
