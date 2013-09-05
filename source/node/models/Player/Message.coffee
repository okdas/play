module.exports= class Message
    @table: 'message'

    constructor: (data) ->
        @id= data.id
        @playerId= data.playerId
        @content= data.content

    @create: (playerId, message, maria, done) ->
        message= new @ message if not (message instanceof @)
        message.playerId= playerId

        maria.query "
            INSERT
              INTO
                ??
               SET
                ?
            "
        ,   [@table, message]
        ,   (err, res) =>

                if not err and res.affectedRows != 1
                    err= 'message create error'

                if not err
                    message.id= res.insertId

                done err, message
