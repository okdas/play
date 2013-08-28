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


    app.get '/', (req, res, next) ->
        return res.redirect '/player/' if do req.isAuthenticated
        return res.redirect '/welcome/'

    app.get '/player', (req, res, next) ->
        return res.redirect '/welcome/' if do req.isUnauthenticated
        return do next

    app.use App.static "#{__dirname}/../views/templates/Play"


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
    Методы для обработки платежей игрока.
    ###
    app.use '/payment/robokassa'
    ,   require './Play/Payment/Robokassa'
