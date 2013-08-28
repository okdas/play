express= require 'express'
async= require 'async'

crypto= require 'crypto'
sha1= (string) ->
    hash= crypto.createHash 'sha1'
    hash.update string
    return hash.digest 'hex'

access= (req, res, next) ->
    return next 401 if do req.isUnauthenticated
    return do next

###
Методы API для работы c аутентифицированным игроком.
###
app= module.exports= do express



app.post '/players', access, (req, res, next) ->
    ###
    {
        name: '',
        pass: '',
        email: '',
        phone: ''
    }
    ###
    player= req.body
    player.pass= sha1 req.body.pass

    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn if err
                conn.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                    return done err, conn if err
                    conn.query 'START TRANSACTION', (err) ->
                        return done err, conn

        (conn, done) ->
            conn.query 'INSERT INTO player SET ?'
            ,   [player]
            ,   (err, resp) ->
                    if resp.affectedRows != 1
                        err= 'fail'
                    
                    return done err, conn

        (conn, done) ->
            conn.query 'COMMIT', (err) ->
                return done err, conn

    ],  (err, conn) ->
            do conn.end if conn

            return next err if err
            return res.json 200, player


###
Отдает аутентифицированного игрока.
###
app.get '/', access, (req, res, next) ->

    id= req.user.id

    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn

        (conn, done) ->
            conn.query "
                SELECT
                    Player.id,
                    Player.name,
                    PlayerBalance.amount as balance,
                    Subscription.name as subscription
                FROM
                    ?? as Player
                JOIN
                    ?? as PlayerBalance ON PlayerBalance.playerId = Player.id
                LEFT OUTER JOIN
                    ?? as PlayerSubscription ON PlayerSubscription.id = Player.id
                LEFT OUTER JOIN
                    ?? as Subscription ON Subscription.id = PlayerSubscription.id
                WHERE
                    Player.id = ?
                "
            ,   ['player', 'player_balance', 'player_subscription', 'subscription', id]
            ,   (err, resp) ->
                    player= do resp.shift if not err
                    return done err, conn, player

    ],  (err, conn, player) ->
            do conn.end if conn

            return next err if err
            return res.json 400, player if not player
            return res.json 200, player



###
Обновление аутентифицированного игрока.
###
app.put '/', access, (req, res, next) ->
    ###
    {
        newPass: "",
        oldPass: "",
        email: "",
        phone: ""
    }
    ###
    player= req.body

    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn if err
                conn.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                    return done err, conn if err
                    conn.query 'START TRANSACTION', (err) ->
                        return done err, conn

        (conn, done) ->
            if player.newPass
                q= "UPDATE player
                    SET
                        pass = '#{player.newPass}',
                        email = '#{player.email}',
                        phone = '#{player.phone}'
                    WHERE pass = '#{player.oldPass}' AND id = #{req.user.id}"
            else
                q= "UPDATE player
                    SET
                        email = '#{player.email}',
                        phone = '#{player.phone}'
                    WHERE id = #{req.user.id}"

            conn.query q
            ,   (err, resp) ->
                    if resp.affectedRows != 1
                        err= 'fail'
                    
                    return done err, conn

        (conn, done) ->
            conn.query 'COMMIT', (err) ->
                return done err, conn

    ],  (err, conn) ->
            do conn.end if conn

            return next err if err
            return res.json 200, player



###
Выполняет вход игрока.
###
app.post '/login', (req, res, next) ->

    name= req.body.name
    pass= sha1 req.body.pass

    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn

        (conn, done) ->
            conn.query "
                SELECT
                    Player.id,
                    Player.name
                FROM
                    ?? as Player
                WHERE
                    Player.name = ? AND
                    Player.pass = ?
                "
            ,   ['player', name, pass]
            ,   (err, rows) ->
                    player= do rows.shift if not err
                    return done err, conn, player

    ],  (err, conn, player) ->
            do conn.end if conn

            return next err if err
            return res.json 400, player if not player

            req.login player, (err) ->
                return next err if err
                return res.json 200, player



###
Выполняет выход игрока.
###
app.post '/logout', access, (req, res, next) ->
    return res.json 400, null if req.user.name != req.body.name

    do req.logout
    return res.json 200, true



###
Отдает историю пополнений аутентифицированного игрока.
###
app.get '/payment', access, (req, res, next) ->
    data= null
    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn

        (conn, done) ->
            conn.query "
                SELECT
                    payment.id,
                    payment.amount,
                    payment.createdAt,
                    payment.closedAt,
                    payment.status
                FROM
                    player_payment as payment
                WHERE
                    payment.playerId = ?
                "
            ,   [req.user.id]
            ,   (err, rows) ->
                    data= rows if not err
                    return done err, conn

    ],  (err, conn) ->
            do conn.end if conn

            return next err if err
            return res.json 200, data



###
Пополняет счет аутетифицированного игрока.
###
app.post '/payment', access, (req, res, next) ->

    payment=
        id: null
        playerId: req.user.id
        amount: req.body.amount

    async.waterfall [

        (done) ->
            req.db.getConnection (err, conn) ->
                return done err, conn if err
                conn.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                    return done err, conn

        (conn, done) ->
            conn.query "
                INSERT INTO player_payment SET ?
                "
            ,   [payment]
            ,   (err, resp) ->
                    if not err
                        payment.id= resp.insertId
                    return done err, conn

    ],  (err, conn) ->
            do conn.end if conn

            return next err if err
            return res.json 201, payment
