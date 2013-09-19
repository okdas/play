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
    ,   loadServerStorageTags(
            maria.Server.Tag
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
    ,   loadServerStoreTags(
            maria.Server.Tag
        )

    ,   (req, res) ->

            res.json 200, req.store



    ###
    Покупает предмет сервера аутентифицированному игроку.

    Перед покупкой следующие условия должны быть удовлетворены:
    — Покупаемое кол-во предметов делится без остатка на продаваемое кол-во

    Стоимость предмета хранится в базе данных.

    Стоимость зачарованного предмета
    ###
    app.post '/:serverId(\\d+)/store/items/:itemId(\\d+)/order'

    ,   access

    ,   maria(app.get 'db')

    ,   loadServerStore('serverId',
            maria.Server.Store
        )

        # Загружает чары в магазин.
        # Загруженные чары являются экземплярами класса `Server.Store.Enchantment`.
    ,   (req, res, next) ->
            serverId= req.store.serverId
            maria.Server.Store.Enchantment.query serverId, req.maria, (err, enchantments) ->
                if not err
                    req.store.setEnchantments enchantments
                next err

        # Загружает указанный предмет в магазин.
        # Загруженный предмет является экземпляром класса `Server.Store.Item`
    ,   (req, res, next) ->
            itemId= req.param 'itemId'
            maria.Server.Store.Item.get itemId, req.maria, (err, item) ->
                if not err
                    item= req.store.addItem item
                    if item.enchantability and item.enchantments
                        enchantments= []
                        for enchantment in item.enchantments
                            enchantments.push req.store.factoryItemEnchantment enchantment
                        item.enchantments= enchantments
                next err

    ,   maria.transaction()

        # Списывает стоимость предмета со счета игрока.
    ,   (req, res, next) ->
            playerId= req.user.id
            orig= req.store.getItem req.body.item
            item= req.item= req.store.factoryItem req.body.item
            xp= item.calcXp() - orig.calcXp()
            price= Math.round( ((xp * 0.03) + orig.price) * 100 ) / 100
            price= price * (item.amount / orig.amount)
            maria.Player.Balance.dec playerId, price, req.maria, (err) ->
                next err

        # Сохраняет предмет игроку.
    ,   (req, res, next) ->
            playerId= req.user.id
            serverId= req.store.serverId
            maria.Player.Item.create playerId, serverId, req.item, req.maria, (err, item) ->
                item.enchantments= req.item.enchantments
                req.item= item
                next err

        # Сохраняет чары предмета игроку.
    ,   (req, res, next) ->
            return do next if not req.item.enchantments
            maria.Player.Item.Enchantment.saveItemEnchantments req.item, req.maria, (err, item) ->
                req.item= item
                next err

    ,   maria.transaction.commit()

    ,   (req, res, next) ->
            res.json 201, req.item



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
        playerId= req.user.id
        serverId= req.storage.serverId
        ServerStorageItem.query playerId, serverId, req.maria, (err, items) ->
            req.storage.items= items
            if not items and not err
                res.status 404
                err= 'server storage items not found'
            if not err
                idx= {}
                items= []
                for item, i in req.storage.items
                    if not item.name and not item.enchantability
                        if not itm= idx[item.itemId]
                            itm= idx[item.itemId]= item
                            items.push itm
                        else
                            itm.amount= itm.amount + item.amount
                    else
                        items.push item
                req.storage.items= items
            next err

loadServerStorageTags= (ServerTag) ->
    (req, res, next) ->
        serverId= req.storage.serverId

        console.log 'load server `%s` storage tags...', serverId

        ServerTag.query serverId, req.maria, (err, tags) ->
            req.storage.tags= tags

            if not tags and not err
                res.status 404
                err= 'server storage tags not found'

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
            item.enchantments= []
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

loadServerStoreTags= (ServerTag) ->
    (req, res, next) ->
        serverId= req.store.serverId

        console.log 'load server `%s` store tags...', serverId

        ServerTag.query serverId, req.maria, (err, tags) ->
            req.store.tags= tags

            if not tags and not err
                res.status 404
                err= 'server store tags not found'

            console.log 'load server store:', req.store
            next err
