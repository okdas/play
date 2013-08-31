express= require 'express'
extend= require 'extend'

###
Методы API для работы c магазином.
###
app= module.exports= do express
app.on 'mount', (parent) ->



    ###
    Отдает список серверов аутентифицированному игроку.
    ###
    app.get '/'
    ,   access
    ,   maria(app.get 'db')

    ,   loadServers(maria.Server)

    ,   (req, res) ->

            res.json 200, req.servers

    ###
    Отдает склад сервера аутентифицированному игроку.
    ###
    app.use require './Server/Storage'

    ###
    Отдает магазин сервера аутентифицированному игроку.
    ###
    app.use require './Server/Store'



access= (req, res, next) ->
    return next 401 if do req.isUnauthenticated
    return do next

maria= () ->
    (req, res, next) ->
        req.maria= null

        console.log 'maria...'

        req.db.getConnection (err, conn) ->
            if not err
                req.maria= conn

                req.on 'end', () ->
                    if req.maria
                        req.maria.end () ->
                            console.log 'request end', arguments

                console.log 'maria.'

                conn.on 'error', () ->
                    console.log 'error connection', arguments

            next err

loadServers= (Server) ->
    (req, res, next) ->
        req.servers= null

        console.log 'load servers...'

        Server.query req.maria, (err, servers) ->
            req.servers= servers

            console.log 'load servers:', req.servers
            next err



maria.Server= class Server
    @table: 'server'

    constructor: (data) ->
        @id= data.id
        @name= data.name
        @title= data.title

    @query: (maria, done) ->
        maria.query "
            SELECT
                Server.id,
                Server.name,
                Server.title
            FROM
                ?? as Server
            "
        ,   [@table]
        ,   (err, rows) =>

                if not err
                    servers= []
                    for row in rows
                        servers.push new @ row

                done err, servers

    @get: (name, maria, done) ->
        maria.query "
            SELECT
                Server.id,
                Server.name,
                Server.title
            FROM
                ?? as Server
            WHERE
                Server.name = ?
            "
        ,   [@table, name]
        ,   (err, rows) ->

                server= null
                if not err
                    server= rows[0] or null

                done err, server
