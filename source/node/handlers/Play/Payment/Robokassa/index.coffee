express= require 'express'
async= require 'async'



###
Методы для работы c платежным шлюзом.
###
app= module.exports= do express

app.on 'mount', (parent) -> # монтирует модуль к приложению
    app.set 'config', config= parent.get 'config'



    Robokassa= require 'robokassa'
    robokassa= new Robokassa config.payment.robokassa



    ###
    Обрабатывает оповещение об оплате (ResultURL)
    ###
    app.post '/result', (req, res, next) ->

        data= req.body
        payment= null

        async.waterfall [

            (done) -> # проверяет контрольную сумму оповещения
                robokassa.checkPaymentResult data, (err, result) ->
                    payment= result if not err
                    return done err

            (done) -> # подключается к базе, начинает транзакцию
                req.db.getConnection (err, conn) ->
                    return done err, conn if err
                    conn.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                        return done err, conn if err
                        conn.query 'START TRANSACTION', (err) ->
                            conn.transaction= true if not err
                            return done err, conn

            (conn, done) -> # закрывает платеж, если открыт
                conn.query "
                    UPDATE
                        ?? as PlayerPayment
                    SET
                        PlayerPayment.amount = ?,
                        PlayerPayment.status = ?,
                        PlayerPayment.closedAt = NOW()
                    WHERE
                        PlayerPayment.id = ? AND
                        PlayerPayment.closedAt IS NULL
                    "
                ,   ['player_payment', payment.OutSum, 'success', payment.InvId]
                ,   (err, resp) ->
                        err= err or resp.changedRows != 1
                        return done err, conn

            (conn, done) -> # обновляет баланс игрока
                conn.query "
                    UPDATE
                        ?? as PlayerBalance
                    SET
                        PlayerBalance.amount = PlayerBalance.amount + ?
                    WHERE
                        PlayerBalance.playerId = (
                            SELECT
                                PlayerPayment.playerId
                            FROM
                                ?? as PlayerPayment
                            WHERE
                                PlayerPayment.id = ? AND
                                PlayerPayment.closedAt IS NOT NULL
                        )
                    "
                ,   ['player_balance', payment.OutSum, 'player_payment', payment.InvId]
                ,   (err, resp) ->
                        console.log 'баланс обновлен', resp
                        return done err, conn

            (conn, done) -> # завершает транзакцию
                conn.query 'COMMIT', (err) ->
                    conn.transaction= null if not err
                    return done err, conn

        ],  (err, conn) ->

                async.waterfall [

                    (done) -> # журналирует ошибку
                        return done null if not err
                        console.log err
                        return done null

                    (done) -> # откатывает начатую транзакцию
                        return done null if not conn or not conn.transaction
                        conn.query 'ROLLBACK', (err) ->
                            conn.transaction= null if not err
                            return done err

                    (done) -> # закрывает соединение
                        return done null if not conn
                        conn.end (err) ->
                            return done err

                ],  (err) ->
                        do conn.destroy if conn and err

                        return next err if err
                        return res.send "OK#{payment.InvId}"



    ###
    Обрабатывает переадресацию при успешной оплате (SuccessURL)
    ###
    app.get '/success', (req, res, next) ->
        data= req.query
        robokassa.checkPaymentSuccess data, (err, payment) ->
            return next err if err
            return res.redirect "/#/player/payments/#{payment.InvId}"



    ###
    Обрабатывает переадресацию при отказе от оплаты (FailureURL)
    ###
    app.get '/failure', (req, res, next) ->

        playerId= req.user.id
        data= req.query

        async.waterfall [

            (done) -> # подключается к базе, начинает транзакцию
                req.db.getConnection (err, conn) ->
                    return done err, conn if err
                    conn.query 'SET sql_mode="STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE"', (err) ->
                        return done err, conn if err
                        conn.query 'START TRANSACTION', (err) ->
                            conn.transaction= true if not err
                            return done err, conn

            (conn, done) -> # закрывает платеж, если открыт
                conn.query "
                    UPDATE
                        ?? as PlayerPayment
                    SET
                        PlayerPayment.status = ?,
                        PlayerPayment.closedAt = NOW()
                    WHERE
                        PlayerPayment.id = ? AND
                        PlayerPayment.playerId = ? AND
                        PlayerPayment.closedAt IS NULL
                    "
                ,   ['player_payment', 'failure', playerId, payment.InvId]
                ,   (err, resp) ->
                        err= err or resp.changedRows != 1
                        return done err, conn

            (conn, done) -> # завершает транзакцию
                conn.query 'COMMIT', (err) ->
                    conn.transaction= null if not err
                    return done err, conn

        ],  (err, conn) ->

                async.waterfall [

                    (done) -> # журналирует ошибку
                        return done null if not err
                        console.log err
                        return done null

                    (done) -> # откатывает начатую транзакцию
                        return done null if not conn or not conn.transaction
                        conn.query 'ROLLBACK', (err) ->
                            conn.transaction= null if not err
                            return done err

                    (done) -> # закрывает соединение
                        return done null if not conn
                        conn.end (err) ->
                            return done err

                ],  (err) ->
                        do conn.destroy if conn and err

                        return res.redirect "/player/#/player/payments/#{payment.InvId}"



    ###
    Эмулирует Робокассу для отладочных нужд
    ###
    app.configure 'development', ->
        request= require 'request'

        app.post '/debug', (req, res, next) ->
            data= req.body
            robokassa.checkPayment data, (err, payment) ->
                return next err if err

                robokassa.buildPaymentResult payment, (err, result) ->
                    return next err if err

                    request
                        method: 'POST'
                        uri: config.payment.robokassa.resultUrl
                        form: result
                    ,   (err, res, body) ->
                            if body == "OK#{result.InvId}"
                                console.log 'result response success'

                robokassa.buildPaymentSuccess payment, (err, payment) ->
                    return next err if err

                    url= require 'url'
                    urlObj= url.parse config.payment.robokassa.successUrl
                    urlObj.query= payment

                    return res.redirect url.format urlObj
