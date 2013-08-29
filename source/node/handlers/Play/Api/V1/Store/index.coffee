express= require 'express'
async= require 'async'

access= (req, res, next) ->
    return next 401 if do req.isUnauthenticated
    return do next


class Item
    constructor: (data) ->
        @id= data.itemId
        @name= data.itemName
        @titleRu= data.itemTitleRu
        @titleEn= data.itemTitleEn
        @price= data.itemPrice
        @amount= data.itemAmount
        @material= data.itemMaterial
        @imageUrl= data.itemImageUrl
        @enchantability= data.itemEnchantability

        @enchantments= [] if data.itemEnchantability


class Enchantment
    constructor: (data) ->
        @id= data.enchantmentId
        @titleRu= data.enchantmentTitleRu
        @titleEn= data.enchantmentTitleEn
        @levelMax= data.enchantmentLevelMax
        @level= data.enchantmentLevel
        @order= data.enchantmentOrder


class Ench
    constructor: (data) ->
        @id= data.id
        @level= data.level
        @levelMin= data.levelMin
        @levelMax= data.levelMax


calcXpForLevel= (pLevel) ->
    if 17 > pLevel
        return 17 * pLevel
    if 16 < pLevel and 32 > pLevel
        return (1.5 * (pLevel * pLevel)) - (29.5 * pLevel) + 360
    if 31 < pLevel
        return (3.5 * (pLevel * pLevel)) - (151.5 * pLevel) + 2220

calcXpForEnchantment= (eLevel, enchantability) ->
    pLevel= Math.floor eLevel - (1 + (enchantability / 2))
    return calcXpForLevel Math.max 1, pLevel


###
Методы API для работы c магазином.
###
app= module.exports= do express



###
Отдает магазин аутентифицированному игроку.
###
app.get '/', access, (req, res, next) ->
    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn

        (conn, done) ->
            # Извлечь все предметы магазина
            conn.query "
                SELECT
                    item.id as itemId,
                    item.title as itemTitle,
                    item.price as itemPrice,
                    server.id as serverId,
                    server.name as serverName,
                    server.title as serverTitle
                FROM ?? as Item
                LEFT OUTER JOIN store_item_servers as itemServers
                    ON itemServers.itemId = item.id
                JOIN server as server
                    ON server.id= itemServers.serverId
                "
            ,   ['item']
            ,   (err, rows) ->
                    return done err, conn, rows

        (conn, rows, done) ->
            servers= []
            serversIndex= {}
            serversItemsIndex= {}
            for row in rows
                server= serversIndex[row.serverId]
                if not server
                    server= serversIndex[row.serverId]=
                        id: row.serverId
                        name: row.serverName
                        title: row.serverTitle
                        store:
                            items: []
                        storage:
                            items: []
                    servers.push server
                    serversItemsIndex[row.serverId]= {}
                item= serversItemsIndex[row.serverId][row.itemId]
                if not item
                    item= serversItemsIndex[row.serverId][row.itemId]=
                        id: row.itemId
                        title: row.itemTitle
                        price: row.itemPrice
                    server.store.items.push item
            return done null, conn, servers

    ],  (err, conn, servers) ->
            do conn.end if conn

            return next err if err
            return res.json 200,
                servers: servers





maria= () ->
    (req, res, next) ->
        req.maria= null

        console.log 'maria...'

        req.db.getConnection (err, conn) ->
            if not err
                req.maria= conn

                req.on 'end', () ->
                    console.log 'request end', arguments

                console.log 'maria.'

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

    constructor: () ->



maria.Server.Enchantment= class ServerEnchantment
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



maria.Server.Item= class ServerItem

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



maria.Server.Item.Enchantment= class ServerItemEnchantment

    @table= 'item_enchantment'


    constructor: (data) ->
        
        @itemId= data.itemId
        @enchantmentId= data.enchantmentId
        
        @level= data.level


    @queryByIds: (ids, maria, done) ->
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



loadServers= (Server) ->
    (req, res, next) ->
        req.servers= null

        console.log 'load servers...'

        Server.query req.maria, (err, servers) ->
            req.servers= servers

            console.log 'servers.', arguments

            next err



loadServer= (name, Server) ->
    (req, res, next) ->
        req.server= null

        name= req.param name

        console.log "load server (#{name})..."

        Server.get name, req.maria, (err, server) ->
            req.server= server

            console.log 'server (#{name}).', arguments

            next err



loadServerEnchantments= (ServerEnchantment) ->
    (req, res, next) ->
        req.server.enchantments= null

        serverId= req.server.id

        console.log "load server (#{serverId}) enchantments..."

        ServerEnchantment.query serverId, req.maria, (err, enchantments) ->
            req.server.enchantments= enchantments

            console.log "server (#{serverId}) enchantments."

            next err



loadServerItems= (ServerItem) ->
    (req, res, next) ->
        req.server.items= null

        serverId= req.server.id

        console.log "load server (#{serverId}) items..."

        ServerItem.query serverId, req.maria, (err, items) ->
            req.server.items= items

            console.log "server (#{serverId}) items."

            next err



loadServerItemsEnchantments= (ServerItemEnchantment) ->
    (req, res, next) ->
        
        serverId= req.server.id

        idx= {}
        ids= []
        for item in req.server.items
            if not item.enchantability
                continue
            if not idx[item.id]
                idx[item.id]= item
                ids.push item.id

                item.enchantments= []

        console.log "load server `#{serverId}` items enchantments..."

        ServerItemEnchantment.queryByIds ids, req.maria, (err, enchantments) ->

            console.log ids, enchantments

            if not err
                for ench in enchantments
                    item= idx[ench.itemId]
                    if item
                        item.enchantments.push
                            id: ench.id
                            level: ench.level

            console.log "server `#{serverId}` items enchantments."

            next err



###
Отдает список серверов аутентифицированному игроку.
###
app.get '/servers'
,   access
,   maria(app.get 'db')

,   loadServers(maria.Server)

,  (req, res) ->

        res.json 200, req.servers



###
Отдает магазин сервера аутентифицированному игроку.
###
app.get '/servers/:serverName'
,   access
,   maria(app.get 'db')

,   loadServer('serverName', maria.Server)
,   loadServerEnchantments(maria.Server.Enchantment)
,   loadServerItems(maria.Server.Item)
,   loadServerItemsEnchantments(maria.Server.Item.Enchantment)

, (req, res) ->

        res.json 200, req.server



app.post '/servers/:serverId(\\d+)/items/:itemId/order', access, (req, res, next) ->

    playerId= req.user.id
    serverId= req.params.serverId

    itemId= req.params.itemId

    item= req.body.item
    orig= null

    item.amount= item.amount|0 or 1

    price= 0
    balance= 0

    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn if err
                conn.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                    return done err, conn if err
                    conn.query 'START TRANSACTION', (err) ->
                        conn.transaction= true if not err
                        return done err, conn

        # выяснить стоимость предмета
        (conn, done) ->
            console.log 'order', item
            conn.query "
                SELECT
                    Item.id,
                    Item.price,
                    Material.enchantability
                FROM
                    ?? as ServerItem
                JOIN
                    ?? as Item
                    ON Item.id = ServerItem.itemId
                JOIN
                    ?? as Material
                    ON Material.id = Item.material
                WHERE
                    ServerItem.serverId = ? AND
                    ServerItem.itemId = ?
                "
            ,   ['server_item', 'item', 'bukkit_material', serverId, itemId]
            ,   (err, rows) ->
                    if not err
                        orig= do rows.shift
                        if not orig
                            return done 'item not exists', conn

                        # посчитать стоимость кол-ва предметов
                        price= item.amount * orig.price

                    return done err, conn

        # выбрать чары предмета
        (conn, done) ->

            # пропустить шаг если предмет не может быть зачарован
            if not orig.enchantability
                return done null, conn

            # выбрать чары
            conn.query "
                SELECT
                    Enchantment.id,
                    Enchantment.levelmax as levelMax,
                    ItemEnchantment.level
                FROM
                    ?? as ItemEnchantment
                JOIN
                    ?? as Enchantment
                    ON Enchantment.id = ItemEnchantment.enchantmentId
                WHERE
                    ItemEnchantment.itemId = ?
                ORDER BY
                    ItemEnchantment.order ASC
                "
            ,   ['item_enchantment', 'bukkit_enchantment', orig.id]
            ,   (err, rows) ->
                    if not err
                        orig.enchantments= []
                        for row in rows
                            orig.enchantments.push row
                    return done err, conn

        # выбрать добавленные чары
        (conn, done) ->

            # пропустить шаг если предмет не может быть зачарован
            if not orig.enchantability
                return done null, conn

            # пропустить шаг если чары не добавлены на предмет
            if not item.enchantments or not item.enchantments.length
                return done null, conn

            # построить индекс добавленых чар
            ids= []
            idx= {}
            for enchantment in item.enchantments
                idx[enchantment.id]= enchantment
                ids.push enchantment.id

            # выбрать чары
            conn.query "
                SELECT
                    Enchantment.id,
                    Enchantment.levelMax,
                    Enchantment.levelMin
                FROM
                    ?? as Enchantment
                WHERE
                    Enchantment.id IN(?)
                "
            ,   ['bukkit_enchantment', ids]
            ,   (err, rows) ->
                    if not err
                        idxx= []
                        for row in rows
                            enchantment= idx[row.id]
                            # пропустить чары если их уровень выше максимального
                            if enchantment.level > row.levelMax
                                continue
                            # пропустить чары если их уровень ниже минимального
                            if enchantment.level < row.levelMin
                                continue
                            idxx[row.id]= enchantment
                        # восстановить пользовательский порядок чар
                        item.enchantments= []
                        for id in ids
                            enchantment= idxx[id]
                            if not enchantment
                                continue
                            item.enchantments.push enchantment
                    return done err, conn

        # посчитать стоимость добавленных чар
        (conn, done) ->

            # пропустить шаг если чары не добавлены на предмет
            if not item.enchantments or not item.enchantments.length
                return done null, conn

            # собрать все чары предмета
            idx= {}
            enchantments= []

            for data in orig.enchantments
                # сначала оригинальные чары
                ench= idx[data.id]= new Ench data
                enchantments.push idx[data.id]

            for data in item.enchantments
                # затем пользовательские чары
                ench= idx[data.id]
                if ench
                    ench.level= data.level
                else
                    enchantments.push new Ench data

            item.enchantments= enchantments

            origXp= 0
            for ench in orig.enchantments
                origXp= origXp + calcXpForEnchantment ench.level, orig.enchantability

            itemXp= 0
            for ench in item.enchantments
                itemXp= itemXp + calcXpForEnchantment ench.level, orig.enchantability

            diffXp= itemXp - origXp

            # посчитать стоимость, округлить
            price= Math.round( ((diffXp * 0.03) + orig.price) * 100 ) / 100

            console.log 'разница опыта', diffXp, 'цена', price

            return done null, conn

        # проверить наличие требуемой суммы у пользователя
        (conn, done) ->
            conn.query "
                UPDATE
                    ?? as PlayerBalance
                SET
                    PlayerBalance.amount = PlayerBalance.amount - ?
                WHERE
                    PlayerBalance.amount >= ? AND
                    PlayerBalance.playerId = ?
                "
            ,   ['player_balance', price, price, playerId]
            ,   (err, resp) ->
                    if not err and resp.changedRows != 1
                        err= 'not enough money'
                    return done err, conn

        # сохранить предмет пользователю
        (conn, done) ->
            conn.query "
                INSERT INTO
                    ?? (
                    playerId, serverId, material, name, titleRu, titleEn, amount
                ) SELECT
                    ?,
                    ?,
                    material,
                    name,
                    titleRu,
                    titleEn,
                    ?
                FROM
                    ?? as Item
                WHERE
                    Item.id = ?
                "
            ,   ['player_item', playerId, serverId, item.amount, 'item', item.id]
            ,   (err, resp) ->
                    if not err and resp.affectedRows == 1
                        item.id= resp.insertId
                    return done err, conn

        # сохранить чары предмета
        (conn, done) ->

            # пропустить шаг если предмет не имеет чар
            if not item.enchantments or not item.enchantments.length
                return done null, conn

            bulk= []
            for ench, i in item.enchantments
                bulk.push [item.id, ench.id, ench.level, i]

            conn.query "
                INSERT INTO
                    ??
                (
                    `itemId`, `enchantmentId`, `level`, `order`
                ) VALUES
                    ?
                "
            ,   ['player_item_enchantment', bulk]
            ,   (err, resp) ->
                    if not err and resp.affectedRows != item.enchantments.length
                        err= 'not inserted player item enchantments'
                    return done err, conn

        (conn, done) ->
            conn.query "
                COMMIT
                "
            ,   (err) ->
                    if not err
                        conn.transaction= false
                    return done err, conn

    ],  (err, conn) ->
            async.waterfall [
                (done) ->
                    if not conn or not conn.transaction
                        return done null
                    conn.query "ROLLBACK", (err) ->
                        return done err
                (done) ->
                    if not conn
                        return done null
                    conn.end (err) ->
                        return done err
            ],  (er) ->
                    do conn.destroy if er

                    return next err if err
                    return res.json 201, item
