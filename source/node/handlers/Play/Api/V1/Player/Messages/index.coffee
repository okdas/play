express= require 'express'

###
Методы API для отправки сообщений разработчикам
###
app= module.exports= do express
app.on 'mount', (parent) ->
    app.set 'maria', maria= parent.get 'maria'

    ###
    Создает сообщение.
    ###
    app.post '/'
    ,   access

    ,   maria(
            app.get 'db'
        )

    ,   maria.transaction()

    ,   createMessage(
            maria.Player.Message
        )

    ,   maria.transaction.commit()

    ,   (req, res) ->

            res.json 201, req.message



access= (req, res, next) ->
    return next 401 if do req.isUnauthenticated
    return do next

createMessage= (Message) ->
    (req, res, next) ->
        playerId= req.user.id

        message= new Message req.body
        Message.create playerId, message, req.maria, (err, message) ->
            req.message= message or null

            if not err and not message.id
                res.status 400
                err= 'message create error'

            return next err
