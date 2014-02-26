`ct` is a network cross-traffic generator implementation using NodeJS.

Rationale
=========

In order to test custom software-defined networks built using [mininet](http://www.mininet.org/), I needed a tool to stress test the network data plane capacity in terms of latency and throughput. The tools I found so far on the web either measure latency or throughput, but not both of them simultaneously over the same data flow. Hence, I came up with my own implementation, called `ct`.

In a nutshell, `ct` provides a server and a set of client applications, where each type of client conveys a different type of flow generation scheme. In the overall picture, multiple clients continuously pump data to the given servers over TCP. In the meantime, servers collect throughput and latency statistics on a per client basis.

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

`ct` ships a single server executable: `server.exec.js`.

	$ node out/exec/server.exec.js
	Start the cross-traffic server.
	Usage: node ./out/exec/server.exec.js

	Options:
	  -f, --reportFile  report output file  [required]

	Missing required arguments: f

By default there are two types of clients shipped as follows.

Periodic Cross-Traffic Client
-----------------------------

`periodicClient.exec.js` generates (and maintains) given number of concurrent connections to the specified set of servers. Generated flows has a constant lifetime with a parametrized variation.

	$ node out/exec/periodicClient.exec.js
	Start the periodic cross-traffic client.
	Usage: node ./out/exec/periodicClient.exec.js

	Options:
	  -f, --serverAddressFile        file containing list of server addresses in JSON        [required]
	  -x, --excludedServerAddresses  whitespace separated list of excluded server addresses  [default: ""]
	  -c, --nConns                   number of concurrent connections                        [required]
	  -h, --hostId                   host id                                                 [required]
	  -l, --lifetime                 flow lifetime                                           [required]
	  -v, --lifetimeVariance         variation window of the flow lifetime                   [required]

	Missing required arguments: f, c, h, l, v

You can employ `periodicClient.exec.js` in your `mininet` setup as follows. First, start a set of `ct` servers on server hosts:

	$ node out/exec/server.exec.js --reportFile /tmp/server.dat

Next, write down the list of server IP addresses to a file.

	$ echo '["127.0.0.1"]' >/tmp/serverAddresses.json

Finally, start clients by providing necessary command line arguments.

	$ node out/exec/periodicClient.exec.js \
		--serverAddressFile /tmp/serverAddresses.json
		--nConns 10 \
		--hostId 1 \
		--lifetime 10000 \
		--lifetimeVariance 3000

Here, we start a client that is supposed to connect to a single server running at `127.0.0.1`. Client will try to maintain `nConns=10` concurrent connections at a time. (The server for each connection will be picked randomly.) `hostId` is the identifier of the current client. Server will use this information to differentiate statistics for each client in the reports. `lifetime=10000` and `lifetimeVariance=3000` instructs client to generate flows with a lifetime of 10±3 seconds.

A client continuously pushes data over TCP to the servers using given number of concurrent connections. When you interrupt a server (via `^C`) it will write down the statistics collected so far to the specified `reportFile` as follows.

	$ cat /tmp/server.dat
	data throughput to host 1: 46126.948121987814 bytes/ms
	data latency to host 1: 171.35418041643547 ms
	total data throughput: 455082.68570153916 bytes/ms
	total data latency: 171.35418041643547 ms
	total connection throughput: 0.0010692720563569272 conns/ms

Note that *data throughput to host 1* is nearly 10-times less than the *total data throughput*. This is due to the fact that, first we compute the throughput of each flow individually and then take the mean of these individual throughputs to compute the throughput of a single host. Hence, since there are 10 concurrent connections, *(data throughput to host 1) x 10 ~= total data throughput*.

Random Cross-Traffic Client
---------------------------

`randomClient.exec.js` generates instantaneous flows to the specified set of servers. While doing so, flow inter-arrival time is set to be exponentially distributed and flow lifetimes are picked randomly from the range `[0, 10)`.

	$ node out/exec/randomClient.exec.js
	Start the random cross-traffic client.
	Usage: node ./out/exec/randomClient.exec.js

	Options:
	  -f, --serverAddressFile        file containing list of server addresses in JSON        [required]
	  -x, --excludedServerAddresses  whitespace separated list of excluded server addresses  [default: ""]
	  -h, --hostId                   host id                                                 [required]

	Missing required arguments: f, h

Caveats
=================

While periodic client keeps the socket creation rate at a regular pace, random clients can quickly exhaust the available port space due to `TIME-WAIT` sockets in a few seconds. In order to alleviate this problem, you might consider enabling TCP time-wait socket recycling (that is, `net.ipv4.tcp_tw_recycle`) in the kernel.

License
=======

Copyright &copy; 2014, Volkan Yazıcı

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the name of the <organization> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
