module.exports= class ServerStoreItem

    @Enchantment= require './Item/Enchantment'



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
        @enchantments= data.enchantments or null
        @tags= data.tags or null

    addEnchantment: (data) ->
        if not @enchantability
            return
        if not @enchantments or not @enchantments.length
            @enchantments= []
        @enchantments.push enchantment= new @constructor.Enchantment data
        enchantment.id= data.id
        enchantment

    calcXp: () ->
        xp= 0
        if @enchantments and @enchantments.length
            for enchantment in @enchantments
                xp= xp + calcXpForEnchantment enchantment.level, @enchantability
        xp



    @table= 'server_item'
    @tableItem= 'item'
    @tableMaterial= 'bukkit_material'
    @tableItemEnchantment= 'item_enchantment'
    @tableItemTag= 'item_tag'



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
                Material.enchantability as enchantability,

                GROUP_CONCAT(ItemTag.tagId) as tags

              FROM
                ?? as ServerItem
              JOIN
                ?? as Item
                ON Item.id= ServerItem.itemId
              JOIN
                ?? as Material
                ON Material.id= Item.material
              LEFT OUTER JOIN
                ?? as ItemTag
                ON ItemTag.itemId= Item.id

             WHERE
                ServerItem.serverId = ?

             GROUP BY
                Item.id
            "
        ,   [@table, @tableItem, @tableMaterial, @tableItemTag, serverId]
        ,   (err, rows) =>

                if not err
                    items= []
                    for row in rows
                        items.push new @ row

                done err, items

    @get: (itemId, maria, done) ->
        item= null

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
                Material.enchantability as enchantability,

                GROUP_CONCAT(DISTINCT CONCAT(ItemEnchantment.enchantmentId, ':', ItemEnchantment.level)
                    ORDER BY ItemEnchantment.order
                ) as enchantments

              FROM
                ?? as ServerItem
              JOIN
                ?? as Item
                ON Item.id= ServerItem.itemId
              JOIN
                ?? as Material
                ON Material.id= Item.material
              LEFT OUTER JOIN
                ?? as ItemEnchantment
                ON ItemEnchantment.itemId= Item.id

             WHERE
                ServerItem.itemId = ?
            "
        ,   [@table, @tableItem, @tableMaterial, @tableItemEnchantment, itemId]
        ,   (err, rows) =>

                if not err
                    row= null
                    if row= do rows.shift
                        item= new @ row
                        if item.enchantability
                            enchantments= []
                            for data in item.enchantments.split ','
                                data= data.split ':'
                                enchantments.push new @Enchantment
                                    id: data[0]
                                    level: data[1]
                            item.enchantments= enchantments

                done err, item



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
