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

        app.use (req, res, next) ->
            req.db= app.db
            return do next


    ###
    Обработчики маршрутов приложения
    ###
    app.configure ->
        app.use require './handlers'
