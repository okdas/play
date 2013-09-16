module.exports= class ServerStorageItem
    @table= 'player_item'

    @tableMaterial= 'bukkit_material'
    @tableItemTag= 'item_tag'

    constructor: (data) ->
        @id= data.id
        @amount= data.amount

        @name= data.name

        @titleRu= data.itemTitleRu or data.materialTitleRu
        @titleEn= data.itemTitleEn or data.materialTitleEn

        @imageUrl= data.itemImageUrl or data.materialImageUrl

        @material= data.material
        @enchantability= data.enchantability

        @tags= data.tags or null

        @createdAt= data.createdAt

    @query: (serverId, maria, done) ->
        maria.query "
            SELECT

                PlayerItem.id,
                PlayerItem.amount,

                PlayerItem.name,

                PlayerItem.titleRu as itemTitleRu,
                Material.titleRu as materialTitleRu,

                PlayerItem.titleEn as itemTitleEn,
                Material.titleEn as materialTitleEn,

                PlayerItem.imageUrl as itemImageUrl,
                Material.imageUrl as materialImageUrl,

                Material.id as material,
                Material.enchantability as enchantability,

                GROUP_CONCAT(ItemTag.tagId) as tags,

                PlayerItem.createdAt

              FROM
                ?? as PlayerItem
              JOIN
                ?? as Material
                ON Material.id= PlayerItem.material
              LEFT OUTER JOIN
                ?? as ItemTag
                ON ItemTag.itemId= PlayerItem.id

             WHERE
                PlayerItem.serverId = ?

             GROUP BY
                PlayerItem.id

             ORDER BY
                PlayerItem.createdAt DESC,
                material, CAST(material AS SIGNED)
            "
        ,   [@table, @tableMaterial, @tableItemTag, serverId]
        ,   (err, rows) =>

                items= null
                if not err
                    items= []
                    for row in rows
                        items.push new @ row
                done err, items
