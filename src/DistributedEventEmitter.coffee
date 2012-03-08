###
@file DistributedEventEmitter.coffee
@author Reed McGrew

Copyright 2012, FamilyLink.com, Inc.

This software may be copied and used for any purpose, free of charge, under the conditions of the MIT License, provided this notice is included in each copy of the software.
###

#Includes
express = require 'express'
request = require 'request'
{EventEmitter} = require 'events'

#Private Constants
esl_path = '/consume'
subscribe_path = '/subscribe'

module.exports = class DistributedEventEmitter
    constructor: (opts) ->
        #Handle Settings
        @protocol = 'http' #currently http is the only protocol accepted
        {@host,
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
