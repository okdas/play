module.exports= class ServerStoreItem
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

        @enchantments= [] if @enchantability

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
                ServerItem.itemId = ?
            "
        ,   [@table, @tableItem, @tableMaterial, itemId]
        ,   (err, rows) =>

                if not err
                    row= null
                    if row= do rows.shift
                        item= new @ row

                done err, item
