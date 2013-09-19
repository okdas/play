Item= require '../Item'

module.exports= class PlayerItem extends Item
    @table: 'player_server_item'



    constructor: (data) ->
        @id= data.id
        @playerId= data.playerId
        @serverId= data.serverId
        @itemId= data.itemId
        @amount= data.amount



    @Enchantment= require './Item/Enchantment'

    @create: (playerId, serverId, data, maria, done) ->
        item= new @
            playerId: playerId
            serverId: serverId
            itemId: data.id
            amount: data.amount
        maria.query "
            INSERT INTO
                ??
               SET
                ?
            "
        ,   [@table, item]
        ,   (err, res) ->
                if not err
                    item.id= res.insertId
                done err, item
