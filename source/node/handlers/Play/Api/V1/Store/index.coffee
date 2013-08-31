express= require 'express'
async= require 'async'

extend= require 'extend'
deferred= require 'deferred'


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
                    playerId, serverId, material, name, titleRu, titleEn, imageUrl, amount
                ) SELECT
                    ?,
                    ?,
                    material,
                    name,
                    titleRu,
                    titleEn,
                    imageUrl,
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
