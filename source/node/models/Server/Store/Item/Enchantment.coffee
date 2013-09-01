module.exports= class ServerStoreItemEnchantment
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
