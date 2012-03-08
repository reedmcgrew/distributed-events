# Distributed Events Module
## Overview
This module provides a simple set of tools to write evented APIs.  Currently, there is just one class, DistributedEventEmitter, which is modeled after the node events module.  The only difference is that this class is a server itself, and can emit events to remote subscribers, as well as receive events from remote publishers.

## Installation
This installation assumes you have node.js, npm, and coffeescript already installed.

1. Run the following commands to set up the package:

```bash
git clone git@github.com:AncestryMatchlight/distributed-events.git
cd distributed-events
npm install
sudo npm install -g nodemon
```

2. Copy the distributed-events folder into the node_modules folder of you node.js application.

## Example Usage
```coffeescript
DistributedEventEmitter = require 'distributed-events'
assert = require('assert')
opts1 =
    protocol: 'http'
    host: 'localhost'
    port: 8080
    subscribers: []
    publishers: []
opts2 =
    protocol: 'http'
    host: 'localhost'
    port: 8081
    subscribers: []
    publishers: []

emitter1 = new DistributedEventEmitter(opts1)
emitter2 = new DistributedEventEmitter(opts2)
emitter1.start()
emitter2.start()

emitter1.subscribe_to(emitter2.getSubscribeUrl(), () =>
    emitter1.on "test:received", (payload) =>
        console.log "Event received"
        assert(payload.message is "This is an event body")
        assert(payload._name is "test:received")
        console.log "Success!"
        emitter1.stop()
        emitter2.stop()
    emitter2.emit "test:received", {message:  "This is an event body"}
)
```

## To-Do
