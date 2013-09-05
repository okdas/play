express= require 'express'
extend= require 'extend'

###
Методы API для работы c магазином.
###
app= module.exports= do express
app.on 'mount', (parent) ->
    app.set 'maria', maria= parent.get 'maria'



    ###
    Отдает список серверов аутентифицированному игроку.
    ###
    app.get '/'

    ,   access

    ,   maria(
            app.get 'db'
        )

    ,   loadServers(
            maria.Server
        )

    ,   (req, res) ->

            res.json 200, req.servers



    ###
    Отдает склад сервера аутентифицированному игроку.
    ###
    app.get '/:serverId(\\d+)/storage'

    ,   access

    ,   maria(
            app.get 'db'
        )

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



    ###
    Отдает предмет из магазина сервера аутентифицированному игроку.
    ###
    app.get '/:serverId(\\d+)/store/items/:itemId'

    ,   access

    ,   maria(app.get 'db')

    ,   loadServerStore('serverId',
            maria.Server.Store
        )
    ,   loadServerStoreEnchantments(
            maria.Server.Store.Enchantment
        )
    ,   loadServerStoreItem('itemId',
            maria.Server.Store.Item
        )
    ,   loadServerStoreItemEnchantments(
            maria.Server.Store.Item.Enchantment
        )

    ,   (req, res) ->

            res.json 200, req.store.item



access= (req, res, next) ->
    return next 401 if do req.isUnauthenticated
    return do next

loadServers= (Server) ->
    (req, res, next) ->
        req.servers= null

        console.log 'load servers...'

        Server.query req.maria, (err, servers) ->
            req.servers= servers

            console.log 'load servers:', req.servers
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

loadServerStoreItem= (param, ServerStoreItem) ->
    (req, res, next) ->
        req.store.item= null

        itemId= req.param param

        console.log 'load server store item `%d`...', itemId
        ServerStoreItem.get itemId, req.maria, (err, item) ->
            req.store.item= item
            if not item and not err
                res.status 404
                err= 'server store item not found'

            console.log 'load server store:', req.store
            next err

loadServerStoreItemEnchantments= (ServerStoreItemEnchantment) ->
    (req, res, next) ->

        if not req.store.item.enchantability
            req.store.item.enchantments= null
            return next null

        itemId= req.store.item.id

        req.store.enchantmentsIdx= {}
        for enchantment in req.store.enchantments
            if not req.store.enchantmentsIdx[enchantment.id]
                req.store.enchantmentsIdx[enchantment.id]= enchantment

        console.log 'load server store item `%d` enchantments...', itemId
        ServerStoreItemEnchantment.query [itemId], req.maria, (err, enchantments) ->
            req.store.item.enchantments= []

            if not enchantments and not err
                err= 'cannot load store item enchantments'

            if not err
                ench= null
                for ench in enchantments
                    if enchantment= req.store.enchantmentsIdx[ench.enchantmentId]
                        req.store.item.enchantments.push extend {}, enchantment,
                            level: ench.level

            console.log 'load server store:', req.store
            next err
