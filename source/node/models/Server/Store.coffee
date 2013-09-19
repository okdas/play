module.exports= class ServerStore

    @table= 'server_store'



    @Item= require './Store/Item'
    @ItemEnchantment= require './Store/Item/Enchantment'



    constructor: (data) ->
        @serverId= data.serverId

        @enchantments= []
        Object.defineProperty @, 'enchantmentsIdx',
            value: {}

        @items= []
        Object.defineProperty @, 'itemsIdx',
            value: {}

    addItem: (item) ->
        if not @itemsIdx[item.id]
            @items.push @itemsIdx[item.id]= item
        item

    getItem: (item) ->
        item= @itemsIdx[item.id]
        item

    setEnchantments: (enchantments) ->
        @enchantments= []
        for enchantment in enchantments
            @enchantments.push @enchantmentsIdx[enchantment.id]= enchantment
        @

    getEnchantment: (enchantment) ->
        enchantment= @enchantmentsIdx[enchantment.id]
        enchantment

    factoryItem: (data) ->
        item= @getItem data
        item= new @constructor.Item item
        if data.enchantments
            item.enchantments= []
            for data in data.enchantments
                if ench= @factoryItemEnchantment data
                    item.enchantments.push ench
        item

    factoryItemEnchantment: (data) ->
        ench= @getEnchantment data
        ench= new @constructor.ItemEnchantment ench
        ench.level= data.level |0
        ench



    @get: (serverId, maria, done) ->
        done null, new @
            serverId: serverId
