# Distributed Events Module
## Overview
This module provides a simple set of tools to write evented APIs.  Currently, there is just one class, DistributedEventEmitter, which is modeled after the node events module.  The only difference is that this class is a server itself, and can emit events to remote subscribers, as well as receive events from remote publishers.

## Installation
This installation assumes you have node.js, npm, and coffeescript already installed.
```bash
git clone git@github.com:AncestryMatchlight/distributed-events.git
cd distributed-events
npm install
sudo npm install -g nodemon
```
After running the above commands, you can run the tests to make sure everything is running by typing `sh nodemon_example.sh`

## Example Usage
```coffeescript
DistributedEventEmitter = require('../src/DistributedEventEmitter')
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

emitter1.on "test:received", (payload) =>
    assert(payload.message is "This is an event body")
    assert(payload._name is "test:received")

emitter2.emit event_name, {message:  "This is an event body"}

```

## To-Do
- Make this module a true NPM package.
