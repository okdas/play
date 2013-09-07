App= require 'express'
{Passport}= require 'passport'

SessionStore= require 'connect-redis'
SessionStore= SessionStore App



app= module.exports= do App
app.on 'mount', (parent) ->
    app.set 'config', parent.get 'config'


    passport= new Passport
    passport.serializeUser (user, done) ->
        console.log 'serialize player', user
        done null, user
    passport.deserializeUser (id, done) ->
        console.log 'deserialize player', id
        done null, id

    app.use App.session
        key:'play.sid', secret:'player'
        store: new SessionStore
    app.use do passport.initialize
    app.use do passport.session


    app.enable 'strict routing'

    app.get '/', (req, res, next) ->
        return res.redirect '/welcome/' if do req.isUnauthenticated
        return do next

    app.use '/', App.static "#{__dirname}/../views/templates/Play"

    app.get '/welcome', (req, res, next) ->
        return res.redirect '/welcome/'

    app.get '/welcome/', (req, res, next) ->
        return res.redirect '/' if do req.isAuthenticated
        return do next

    app.use '/welcome', App.static "#{__dirname}/../views/templates/Welcome"


    ###
    Методы API для работы c аутентифицированным игроком.
    ###
    app.use '/api/v1/player'
    ,   require './Play/Api/V1/Player'

    ###
    Методы API для работы c платежами аутентифицированного игрока.
    ###
    app.use '/api/v1/player/payments'
    ,   require './Play/Api/V1/Player/Payments'

    ###
    Методы API для работы с подписками.
    ###
    app.use '/api/v1/player/subscriptions'
    ,   require './Play/Api/V1/Player/Subscriptions'

    ###
    Методы API для работы игрока с магазином.
    ###
    app.use '/api/v1/store'
    ,   require './Play/Api/V1/Store'

    ###
    Методы API для работы с серверами.
    ###
    app.use '/api/v1/servers'
    ,   require './Play/Api/V1/Servers'

    ###
    Методы для обработки платежей игрока.
    ###
    app.use '/payment/robokassa'
    ,   require './Play/Payment/Robokassa'


    ###
    Методы API для отправки сообщений разработчикам
    ###
    app.use '/api/v1/player/messages'
    ,   require './Play/Api/V1/Player/Messages'


    ###
    Обрабатывает ошибку
    ###
    app.use (err, req, res, next) ->
        res.status 500
        res.json
            name: err.name
            message: err.message
