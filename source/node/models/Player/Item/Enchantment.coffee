module.exports= class PlayerItemEnchantment
    @table: 'player_server_item_enchantment'

    @saveItemEnchantments: (item, maria, done) ->
        bulk= []
        for ench, i in item.enchantments
            bulk.push [item.id, ench.id, ench.level, i]
        maria.query "
            INSERT INTO
                ??
            (
                `itemId`, `enchantmentId`, `level`, `order`
            )
            VALUES
                ?
            "
        ,   [@table, bulk]
        ,   (err, res) ->
                if not err and res.affectedRows != item.enchantments.length
                    err= 'error insert player item enchantments'
                done err, item
