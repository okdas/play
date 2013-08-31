express= require 'express'
async= require 'async'

extend= require 'extend'
deferred= require 'deferred'


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


maria.Server.Storage= class ServerStorage
    @table: 'player_item'
    @tableMaterial= 'bukkit_material'

    constructor: (data) ->
        @id= data.id
        @amount= data.amount
        @price= data.price
        
        @name= data.name

        @titleRu= data.itemTitleRu or data.materialTitleRu
        @titleEn= data.itemTitleEn or data.materialTitleEn

        @imageUrl= data.itemImageUrl or data.materialImageUrl

        @material= data.material
        @enchantability= data.enchantability

        @createdAt= data.createdAt

    @get: (serverId, maria, done) ->
        console.log "get server (#{serverId}) storage..."

        maria.query "
            SELECT

                PlayerItem.id,
                PlayerItem.amount,

                PlayerItem.name,

                PlayerItem.titleRu as itemTitleRu,
                Material.titleRu as materialTitleRu,

                PlayerItem.titleEn as itemTitleEn,
                Material.titleEn as materialTitleEn,

                PlayerItem.imageUrl as itemImageUrl,
                Material.imageUrl as materialImageUrl,

                Material.id as material,
                Material.enchantability as enchantability,

                PlayerItem.createdAt
            FROM
                ?? as PlayerItem
            JOIN
                ?? as Material
                ON Material.id= PlayerItem.material
            WHERE
                PlayerItem.serverId = ?
            ORDER BY
                PlayerItem.createdAt DESC,
                material, CAST(material AS SIGNED)
            "
        ,   [@table, @tableMaterial, serverId]
        ,   (err, rows) =>

                storage= null
                if not err
                    storage=
                        items: []
                    for row in rows
                        storage.items.push new @ row
                done err, storage


###
Методы API для работы c магазином.
###
app= module.exports= do express
app.on 'mount', (parent) ->


    loadServers= (Server) ->
        (req, res, next) ->
            req.servers= null

            console.log 'load servers...'

            Server.query req.maria, (err, servers) ->
                req.servers= servers

                console.log 'servers.', arguments

                next err


    loadServerStorage= (param, ServerStorage) ->
        (req, res, next) ->
            serverId= req.param param

            console.log 'load server (%s) storage...', serverId, req.params
            ServerStorage.get serverId, req.maria, (err, storage) ->

                if storage
                    req.storage= storage
                    console.log 'server storage.', arguments

                if not err and not storage
                    err= 404

                next err


    ###
    Отдает список серверов аутентифицированному игроку.
    ###
    app.get '/'
    ,   access
    ,   maria(app.get 'db')

    ,   loadServers(maria.Server)

    ,  (req, res) ->

            res.json 200, req.servers


    ###
    Отдает список серверов аутентифицированному игроку.
    ###
    app.get '/:serverId(\\d+)/storage'
    ,   access
    ,   maria(app.get 'db')

    ,   loadServerStorage('serverId', maria.Server.Storage)

    ,  (req, res) ->

            res.json 200, req.storage