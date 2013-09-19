module.exports= class ServerStorageItem
    @table= 'player_server_item'

    @tableItem= 'item'
    @tableItemMaterial= 'bukkit_material'
    @tableItemEnchantment= 'player_server_item_enchantment'
    @tableItemTag= 'item_tag'

    constructor: (data) ->
        @id= data.id
        @itemId= data.itemId

        @amount= data.amount

        @name= data.name

        @titleRu= data.itemTitleRu or data.materialTitleRu
        @titleEn= data.itemTitleEn or data.materialTitleEn

        @imageUrl= data.itemImageUrl or data.materialImageUrl

        @material= data.material
        @enchantability= data.enchantability

        @tags= data.tags or null

        @createdAt= data.createdAt

    @query: (playerId, serverId, maria, done) ->
        maria.query "
            SELECT

                PlayerItem.id,
                PlayerItem.itemId,

                PlayerItem.amount,

                PlayerItem.name,

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
                ) as enchantments,

                GROUP_CONCAT(ItemTag.tagId) as tags,

                PlayerItem.updatedAt

              FROM
                ?? as PlayerItem
              JOIN
                ?? as Item
                ON Item.id= PlayerItem.itemId
              JOIN
                ?? as Material
                ON Material.id= Item.material
              LEFT OUTER JOIN
                ?? as ItemEnchantment
                ON ItemEnchantment.itemId= PlayerItem.id
              LEFT OUTER JOIN
                ?? as ItemTag
                ON ItemTag.itemId= Item.id

             WHERE
                PlayerItem.playerId = ?
               AND
                PlayerItem.serverId = ?

             GROUP BY
                PlayerItem.id

             ORDER BY
                PlayerItem.updatedAt DESC,
                material, CAST(material AS SIGNED)
            "
        ,   [@table, @tableItem, @tableItemMaterial, @tableItemEnchantment, @tableItemTag, playerId, serverId]
        ,   (err, rows) =>

                items= null
                if not err
                    items= []
                    for row in rows
                        items.push new @ row
                done err, items
