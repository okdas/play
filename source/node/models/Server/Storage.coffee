module.exports= class ServerStorage

    constructor: (data) ->
        @serverId= data.serverId

        @enchantments= []
        @items= []

    @get: (serverId, maria, done) ->
        done null, new @
            serverId: serverId
