module.exports= class ServerStore

    @table= 'server_store'

    constructor: (data) ->
        @serverId= data.serverId

        @enchantments= []
        @items= []

    @get: (serverId, maria, done) ->
        done null, new @
            serverId: serverId