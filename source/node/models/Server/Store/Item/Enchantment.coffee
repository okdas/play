module.exports= class ServerStoreItemEnchantment
    @table= 'item_enchantment'

    constructor: (data) ->
        @id= data.id
        @titleRu= data.titleRu
        @titleEn= data.titleEn
        @levelMin= data.levelMin
        @levelMax= data.levelMax
        @level= data.level

        @itemId= data.itemId
        @enchantmentId= data.enchantmentId

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
