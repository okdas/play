module.exports= class PlayerBalance
    @table: 'player_balance'

    @dec: (playerId, amount, maria, done) ->

        if not amount
            err= new Error 'PlayerBalance#amount cannot be NULL'

        if err
            return done err

        maria.query "
            UPDATE
                ?? as PlayerBalance
            SET
                PlayerBalance.amount = PlayerBalance.amount - ?
            WHERE
                PlayerBalance.amount >= ? AND
                PlayerBalance.playerId = ?
            "
        ,   [@table, amount, amount, playerId]
        ,   (err, res) =>

                if not err and res.affectedRows != 1
                    err= 'not enough money'

                done err
