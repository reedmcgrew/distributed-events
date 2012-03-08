#Includes
express = require 'express'
request = require 'request'
{EventEmitter} = require 'events'

#Private Constants
esl_path = '/consume'
subscribe_path = '/subscribe'

class DistributedEventEmitter
    constructor: (opts) ->
        #Handle Settings
        {@protocol,
        @host,
        @port,
        @subscribers,
        @publishers} = opts

        #Set up local event dispatcher
        @internal_events = new EventEmitter()

        #Create Server
        @_server = express.createServer()
        app = @_server

        #Configure Server
        @_server.configure(() ->
          app.set('views', __dirname + '/views')
          app.set('view engine', 'jade')
          app.use(express.logger())
          app.use(express.bodyParser())
          app.use(express.methodOverride())
          app.use(app.router)
        )
        app.configure('development', () ->
            app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
        )
        app.configure('production', () ->
            app.use(express.errorHandler())
        )

        ###
        # Set up Routes
        ###
        #Publisher
        app.post(subscribe_path, @_handle_subscription)
        app.get("#{subscribe_path}/:remote_esl", @_handle_subscription)
 
        #Subscriber
        app.post(esl_path, @_consume_event)

    _log: (msg, level = "info") =>
        console.log("[#{@host}:#{@port} (#{level})] " + msg)

    ###
    # Route Handlers
    ###
    _handle_subscription: (req,res) =>
        new_esl = decodeURIComponent(req.params.remote_esl)
        @subscribers.push(new_esl)
        @_log "received esl: #{new_esl}", "debug"
        res.end()

    _consume_event: (req,res) =>
        @_log "consuming event with body #{JSON.stringify(req.body)}","debug"

        @internal_events.emit(req.body._name, req.body)
        res.end()


    ###
    # Accessors
    ###
    getEslPath: () =>
        esl_path

    getSubscribePath: () =>
        subscribe_path

    getEsl: () =>
        @getBaseUrl() + @getEslPath()

    getBaseUrl: () =>
        @protocol + "://" + @host + ":" + @port

    getSubscribeUrl: () =>
        @getBaseUrl() + @getSubscribePath()


    ###
    # Event Processing
    ###
    on: (event_name, action) ->
        @internal_events.on event_name, action

    emit: (event_name, data) ->
        log = @_log
        send_event = (subscriber, event_name, data) ->
            data._name = event_name
            opts =
                url: subscriber
                json: data
            log("sending request to #{subscriber}", "debug")
            request.post(opts, (error, response, body) =>
                log("event posted: #{event_name} with data #{JSON.stringify(data)}")
            )
        send_event(esl,event_name,data) for esl in @subscribers

    subscribe_to: (remote_subscribe_url, callback) ->
        full_url = remote_subscribe_url + "/" + encodeURIComponent(@getEsl())
        log = @_log
        log "sending subscription request for esl: #{@getEsl()}", "debug"
        request(full_url, (error, response, body) =>
            log "subscribe_to error: #{error}","debug" if error isnt null
            log "subscribe_to response body: #{body}","debug" if body isnt null
            callback()
        )

    ###
    # Server Management
    ###
    start: (port = null) ->
        port_num = if port isnt null then port else @port
        @_log('Starting server on port ' + port_num + '...')
        @_server.listen(port_num)
        @_log('Server running on port ' + port_num)

    stop: () ->
        @_server.close()

#Consumers to notify can be configured at construct-time OR run-time
#Generators to observe can be configured at construct-time OR run-time

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
