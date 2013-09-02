module.exports= class ServerStoreEnchantment
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
