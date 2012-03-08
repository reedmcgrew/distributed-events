###
 TEST SETUP
###
DistributedEventEmitter = require('../src/DistributedEventEmitter')
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


###
 TESTS
###
# It registers consumers.
# It can register with generators.
exports.itRegistersConsumersWithGenerators = (test) ->
    test.expect 1
    emitter1.subscribe_to(emitter2.getSubscribeUrl(), () =>
        test.ok(emitter1.getEsl() in emitter2.subscribers,
            "emitter 1's esl #{emitter1.getEsl()} is not in emitter2's consumer list: #{emitter2.subscribers}")
        test.done()
    )

# It emits events to consumers.
# It receives events from generators.
exports.itEmitsEventsToConsumersAndConsumersReceiveEvents = (test) ->
    test.expect 2
    payload_message = "This is an event body"
    event_name = "test:received"
    emitter1.on event_name, (payload) =>
        test.ok(payload.message is payload_message)
        test.ok(payload._name is event_name)
        test.done()
        
    emitter2.emit event_name, {message: payload_message}

exports.cleanup = (test) ->
    emitter1.stop()
    emitter2.stop()
    test.done()
