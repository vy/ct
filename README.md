`ct` is a network cross-traffic generator implementation using NodeJS.

Rationale
=========

In order to test custom software-defined networks built using [mininet](http://www.mininet.org/), I needed a tool to stress test the network capacity with latency and throughput measurements. The tools I found so far on the web either measure latency or throughput, but not both of them at the same time over the same data flow. Hence, I came up with my own implementation.

Installation
============

`ct` is written in CoffeeScript on top of NodeJS framework for efficient stream handling and low system overhead. You need to have `npm`, `cake`, and `node` to install, compile and run the program, respectively.

First, you need to clone the repository to your local machine.

	~$ git clone https://github.com/vy/ct.git
	~$ cd ct
	~/ct$ _

Next, run `npm` to install dependencies.

	~/ct$ npm install

Finally, compile the CoffeeScript sources.

	~/ct$ cake compile

Further, you can run unit tests to verify the integrity of the installation.

	~/ct$ cake test

For a complete list of all available build options, run `cake` without any parameters.

Usage
=====

`ct` ships two executables: `server.js`

	$ node out/exec/server.exec.js
	Start the cross-traffic server.
	Usage: node ./out/exec/server.exec.js

	Options:
	  -f, --reportFile  report output file  [required]

	Missing required arguments: f

and `client.js`.

	$ node out/exec/client.exec.js 
	Start the cross-traffic server.
	Usage: node ./out/exec/client.exec.js

	Options:
	  -s, --serverSubnet       server address subnet (e.g., 10.1.0.0/16)  [required]
	  -n, --nServers           number of servers                          [required]
	  -c, --nConns             number of concurrent connections           [required]
	  -h, --hostId             host id                                    [required]
	  -l, --lifetime           flow lifetime                              [required]
	  -t, --lifetimeThreshold  variation window of the flow lifetime      [required]

	Missing required arguments: s, n, c, h, l, t

In your `mininet` setup, start `ct` servers on server hosts as follows.

	$ node out/exec/server.exec.js --reportFile /tmp/server.dat

Next, start clients by providing necessary command line arguments.

	$ node out/exec/client.exec.js \
		--serverSubnet 10.1.0.0/16 \
		--nServers 2 \
		--nConns 10 \
		--hostId 1 \
		--lifetime 10000 \
		--lifetimeThreshold 3000

Here, we start a client that is supposed to connect two servers in subnet `10.1.0.0/16`. Since `nServers` is set to `2`, client will try to connect servers with IP addresses `10.1.0.1` and `10.1.0.2`. Further, client will try to maintain `nConns=10` concurrent connections at a time. (The server for each connection will be picked randomly.) `hostId` is the identifier of the current client. Server will use this information to differentiate statistics for each client in the reports. `lifetime` and `lifetimeThreshold` instructs client to generate flows with a lifetime of 10±3 seconds.

A client continuously pushes data over TCP to the servers using given number of concurrent connections. When you interrupt a server (via `^C`) it will write down the statistics collected so far to the specified `reportFile` as follows.

	$ cat /tmp/server.dat
	data throughput to host 1: 46126.948121987814 bytes/ms
	data latency to host 1: 171.35418041643547 ms
	total data throughput: 455082.68570153916 bytes/ms
	total data latency: 171.35418041643547 ms
	total connection throughput: 0.0010692720563569272 conns/ms

Note that *data throughput to host 1* is nearly 10-times less than the *total data throughput*. This is due to the fact that, first we compute the throughput of each flow individually and then take the mean of these individual throughputs to compute the throughput of a single host. Hence, since there are 10 concurrent connections, *(data throughput to host 1) x 10 ~= total data throughput*.
