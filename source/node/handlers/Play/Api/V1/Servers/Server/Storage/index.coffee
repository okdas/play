express= require 'express'
extend= require 'extend'

###
Методы API для работы c магазином.
###
app= module.exports= do express
app.on 'mount', (parent) ->



    ###
    Отдает склад сервера аутентифицированному игроку.
    ###
    app.get '/:serverId(\\d+)/storage'
    ,   access
    ,   maria(app.get 'db')

    ,   loadServerStorage('serverId',
            maria.Server.Storage
        )
    ,   loadServerStorageEnchantments(
            maria.Server.Store.Enchantment # абстракция протекла
        )
    ,   loadServerStorageItems(
            maria.Server.Storage.Item
        )

    ,   (req, res) ->

            res.json 200, req.storage



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

loadServerStorage= (param, ServerStorage) ->
    (req, res, next) ->
        req.storage= null
        
        serverId= req.param param
        
        console.log 'load server `%d` storage...', serverId
        ServerStorage.get serverId, req.maria, (err, storage) ->

            req.storage= storage

            if not err and not storage
                res.status 404
                err= 'server storage not found'

            console.log 'load server storage:', req.storage
            next err

loadServerStorageEnchantments= (ServerStorageEnchantment) ->
    (req, res, next) ->
        serverId= req.storage.serverId

        console.log 'load server `%d` storage enchantments...'

        ServerStorageEnchantment.query serverId, req.maria, (err, enchantments) ->
            req.storage.enchantments= enchantments

            if not enchantments and not err
                res.status 404
                err= 'server storage enchantments not found'

            console.log 'load server storage:', req.storage
            next err

loadServerStorageItems= (ServerStorageItem) ->
    (req, res, next) ->
        serverId= req.storage.serverId

        console.log 'load server `%s` storage items...', serverId

        ServerStorageItem.query serverId, req.maria, (err, items) ->
            req.storage.items= items

            if not items and not err
                res.status 404
                err= 'server storage items not found'

            console.log 'load server storage:', req.storage
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

    constructor: (data) ->
        @serverId= data.serverId

        @enchantments= []
        @items= []

    @get: (serverId, maria, done) ->
        done null, new @
            serverId: serverId

maria.Server.Storage.Item= class ServerStorageItem
    @table: 'player_item'
    @tableMaterial= 'bukkit_material'

    constructor: (data) ->
        @id= data.id
        @amount= data.amount

        @name= data.name

        @titleRu= data.itemTitleRu or data.materialTitleRu
        @titleEn= data.itemTitleEn or data.materialTitleEn

        @imageUrl= data.itemImageUrl or data.materialImageUrl

        @material= data.material
        @enchantability= data.enchantability

        @createdAt= data.createdAt

    @query: (serverId, maria, done) ->
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

                items= null
                if not err
                    items= []
                    for row in rows
                        items.push new @ row
                done err, items

maria.Server.Store= class ServerStore
maria.Server.Store.Enchantment= class ServerStoreEnchantment
    @table= 'bukkit_enchantment'

    constructor: (data) ->
        @id= data.id
        @titleRu= data.titleRu
        @titleEn= data.titleEn
        @levelMin= data.levelMin
        @levelMax= data.levelMax

    @query: (serverId, maria, done) ->
        enchantments= null

        maria.query "
            SELECT
                ServerEnchantment.id,
                ServerEnchantment.titleRu,
                ServerEnchantment.titleEn,
                ServerEnchantment.levelMin,
                ServerEnchantment.levelMax
            FROM
                ?? as ServerEnchantment
            "
        ,   [@table]
        ,   (err, rows) =>

                if not err
                    enchantments= []
                    for row in rows
                        enchantments.push new @ row

                done err, enchantments
