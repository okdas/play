module.exports= class Player
    @table: 'player'
    @tableBalance: 'player_balance'

    constructor: (data) ->
        @id= data.id
        @name= data.name
        @email= data.email
        @phone= data.phone

        @balance= data.balance if data.balance

    @create: (player, maria, done) ->
        player= new @ player if not (player instanceof @)

        maria.query "
            INSERT
              INTO
                ??
               SET
                ?
            "
        ,   [@table, player]
        ,   (err, res) =>

                if not err and res.affectedRows != 1
                    err= 'player create error'

                if not err
                    player.id= res.insertId
                    delete player.pass if player.pass

                done err, player

    @update: (playerId, player, maria, done) ->
        player= new @ player if not (player instanceof @)

        maria.query "
            UPDATE
                ??
               SET
                ?
             WHERE
                id = ?
            "
        ,   [@table, player, playerId]
        ,   (err, res) =>

                if not err and res.affectedRows != 1
                    err= 'player update error'

                done err, player

    @get: (playerId, maria, done) ->
        maria.query "
            SELECT
                Player.id,
                Player.name,
                Player.email,
                Player.phone,
                IFNULL(PlayerBalance.amount, 0) as balance
              FROM
                ?? as Player
              LEFT OUTER JOIN
                ?? as PlayerBalance ON PlayerBalance.playerId = Player.id
            WHERE
                Player.id = ?
            "
        ,   [@table, @tableBalance, playerId]
        ,   (err, rows) =>
                player= null

                if not err and rows.length
                    player= new @ rows[0]

                console.log 'player', player
                done err, player

    @getByNameAndPass: (player, maria, done) ->
        player= new @ player if not (player instanceof @)

        maria.query "
            SELECT
                Player.id,
                Player.name,
                Player.email,
                Player.phone
              FROM
                ?? as Player
             WHERE
                Player.name = ?
               AND
                Player.pass = ?
               AND
                Player.enabledAt IS NOT NULL
            "
        ,   ['player', player.name, player.pass]
        ,   (err, rows) =>
                player= null

                if not err and rows.length
                    player= new @ rows[0]

                done err, player
