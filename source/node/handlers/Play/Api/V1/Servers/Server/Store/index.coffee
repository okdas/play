express= require 'express'
extend= require 'extend'

###
Методы API для работы c магазином.
###
app= module.exports= do express
app.on 'mount', (parent) ->



    ###
    Отдает магазин сервера аутентифицированному игроку.
    ###
    app.get '/:serverId(\\d+)/store'
    ,   access
    ,   maria(app.get 'db')

    ,   loadServerStore('serverId',
            maria.Server.Store
        )
    ,   loadServerStoreEnchantments(
            maria.Server.Store.Enchantment
        )
    ,   loadServerStoreItems(
            maria.Server.Store.Item
        )
    ,   loadServerStoreItemsEnchantments(
            maria.Server.Store.Item.Enchantment
        )

    ,   (req, res) ->

            res.json 200, req.store



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

loadServerStore= (param, ServerStore) ->
    (req, res, next) ->
        req.store= null

        serverId= req.param param

        console.log 'load server `%d` store...', serverId
        ServerStore.get serverId, req.maria, (err, store) ->

            req.store= store

            if not err and not store
                res.status 404
                err= 'server store not found'

            console.log 'load server store:', req.store
            next err

loadServerStoreEnchantments= (ServerStoreEnchantment) ->
    (req, res, next) ->
        serverId= req.store.serverId

        console.log 'load server `%d` store enchantments...'

        ServerStoreEnchantment.query serverId, req.maria, (err, enchantments) ->
            req.store.enchantments= enchantments

            if not enchantments and not err
                res.status 404
                err= 'server store enchantments not found'

            console.log 'load server store:', req.store
            next err

loadServerStoreItems= (ServerStoreItem) ->
    (req, res, next) ->
        serverId= req.store.serverId

        console.log 'load server `%s` store items...', serverId

        ServerStoreItem.query serverId, req.maria, (err, items) ->
            req.store.items= items

            if not items and not err
                res.status 404
                err= 'server store items not found'

            console.log 'load server store:', req.store
            next err

loadServerStoreItemsEnchantments= (ServerStoreItemEnchantment) ->
    (req, res, next) ->
        serverId= req.store.serverId

        idx= {}
        ids= []
        for item in req.store.items
            if not item.enchantability
                continue
            if not idx[item.id]
                idx[item.id]= item
                ids.push item.id

        console.log 'load server `%d` store items enchantments...', serverId

        enchIdx= {}
        for ench in req.store.enchantments
            if not enchIdx[ench.id]
                enchIdx[ench.id]= ench

        ServerStoreItemEnchantment.query ids, req.maria, (err, enchantments) ->

            if not err
                for itemEnch in enchantments
                    item= idx[itemEnch.itemId]
                    if item
                        ench= enchIdx[itemEnch.enchantmentId]
                        if ench
                            itemEnch= extend {}, ench,
                                level: itemEnch.level
                            item.enchantments.push itemEnch

            console.log 'load server store:', req.store
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

maria.Server.Store= class ServerStore

    @table= 'server_store'

    constructor: (data) ->
        @serverId= data.serverId

        @enchantments= []
        @items= []

    @get: (serverId, maria, done) ->
        done null, new @
            serverId: serverId

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

maria.Server.Store.Item= class ServerStoreItem

    @table= 'server_item'

    @tableItem= 'item'
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

        @enchantments= [] if @enchantability

    @query: (serverId, maria, done) ->
        items= null

        maria.query "
            SELECT

                Item.id,
                Item.amount,
                Item.price,
                Item.name,

                Item.titleRu as itemTitleRu,
                Material.titleRu as materialTitleRu,

                Item.titleEn as itemTitleEn,
                Material.titleEn as materialTitleEn,

                Item.imageUrl as itemImageUrl,
                Material.imageUrl as materialImageUrl,

                Material.id as material,
                Material.enchantability as enchantability

            FROM
                ?? as ServerItem
            JOIN
                ?? as Item
                ON Item.id= ServerItem.itemId
            JOIN
                ?? as Material
                ON Material.id= Item.material
            WHERE
                ServerItem.serverId = ?
            "
        ,   [@table, @tableItem, @tableMaterial, serverId]
        ,   (err, rows) =>

                if not err
                    items= []
                    for row in rows
                        items.push new @ row

                done err, items

maria.Server.Store.Item.Enchantment= class ServerStoreItemEnchantment

    @table= 'item_enchantment'


    constructor: (data) ->
        
        @itemId= data.itemId
        @enchantmentId= data.enchantmentId
        
        @level= data.level


    @query: (ids, maria, done) ->
        enchantments= null

        maria.query "
            SELECT
                
                ItemEnchantment.itemId,
                ItemEnchantment.enchantmentId,

                ItemEnchantment.level

            FROM
                ?? as ItemEnchantment

            WHERE
                ItemEnchantment.itemId IN(?)

            ORDER BY
                ItemEnchantment.order ASC
            "
        ,   [@table, ids]
        ,   (err, rows) =>

                if not err
                    enchantments= []
                    for row in rows
                        enchantments.push new @ row

                done err, enchantments
