App= require 'express'
extend= require 'extend'

###
Возвращает настроенный экзмепляр приложения.
###
module.exports= (cfg, log, done) ->

    ###
    Экземпляр приложения
    ###
    app= do App


    ###
    Конфиг приложения
    ###
    app.configure ->
        config= cfg.default or {}
        app.set 'config', config

    ###
    Конфиг приложения для разработчиков
    ###
    app.configure 'development', ->
        config= app.get 'config'
        extend true, config, cfg.development or {}

    ###
    Конфиг приложения для производства
    ###
    app.configure 'production', ->
        config= app.get 'config'
        extend true, config, cfg.production or {}


    ###
    Логгер приложения
    ###
    app.configure ->
        app.set 'log', log

    ###
    Логгер приложения для разработчиков
    ###
    app.configure 'development', ->
        app.use App.logger 'dev'

    ###
    Логгер приложения для производства
    ###
    app.configure 'production', ->
        app.use (req, res, next) ->
            log.info "#{req.ip} - - #{req.method} #{req.url} \"#{req.headers.referer}\"  \"#{req.headers['user-agent']}\""
            do next


    app.use do App.compress

    app.use App.static "#{__dirname}/views/assets"

    app.use do App.cookieParser
    app.use do App.bodyParser


    ###
    База данных приложения
    ###
    maria= require 'mysql'

    app.configure ->
        config= app.get 'config'

        app.db= maria.createPool config.db

        app.set 'maria', maria= () ->
            (req, res, next) ->
                req.maria= null

                console.log 'maria...'

                req.db.getConnection (err, conn) ->
                    if not err
                        req.maria= conn

                        req.on 'end', () ->
                            if req.maria
                                req.maria.end () ->
                                    console.log 'request end', arguments

                        console.log 'maria.'

                        conn.on 'error', () ->
                            console.log 'error connection', arguments

                    next err

        maria.transaction= () ->
            (req, res, next) ->
                req.maria.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                    return next err if err
                    req.maria.query 'START TRANSACTION', (err) ->
                        req.maria.transaction= true if not err
                        return next err

        maria.transaction.commit= () ->
            (req, res, next) ->
                return do next if not req.maria.transaction
                req.maria.query 'COMMIT', (err) ->
                    return next err

        maria.Player= require './models/Player'
        maria.Player.Pex= require './models/Player/Pex'
        maria.Player.Message= require './models/Player/Message'

        maria.Server= require './models/Server'
        maria.Server.Storage= require './models/Server/Storage'
        maria.Server.Storage.Item= require './models/Server/Storage/Item'
        maria.Server.Store= require './models/Server/Store'
        maria.Server.Store.Enchantment= require './models/Server/Store/Enchantment'
        maria.Server.Store.Item= require './models/Server/Store/Item'
        maria.Server.Store.Item.Enchantment= require './models/Server/Store/Item/Enchantment'


        app.use (req, res, next) ->
            req.db= app.db
            return do next


    ###
    Обработчики маршрутов приложения
    ###
    app.configure ->
        app.use require './handlers'
