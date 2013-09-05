app= angular.module 'app', ['ngAnimate', 'ngRoute', 'ngResource'], ($routeProvider) ->

    $routeProvider.when '/',
        templateUrl: 'partials/', controller: 'IndexRouteCtrl'

    $routeProvider.when '/player',
        templateUrl: 'partials/player/', controller: 'PlayerRouteCtrl', resolve:
            subscriptionList: ($q, Subscription) ->
                dfd= do $q.defer
                Subscription.query (subscriptions) ->
                    dfd.resolve subscriptions
                dfd.promise

    $routeProvider.when '/player/donate/payments',
        templateUrl:'partials/player/donate/payments/', controller:'PlayerPaymentListCtrl'

    $routeProvider.when '/player/donate/payments/:paymentId',
        templateUrl: 'partials/player/donate/payments/payment/', controller:'PlayerPaymentCtrl'

    $routeProvider.when '/store/:server',
        templateUrl: 'partials/servers/', controller: 'StoreServerCtrl'

    $routeProvider.when '/store',
        templateUrl: 'partials/store/', controller: 'StoreCtrl'

    $routeProvider.when '/store/:server',
        templateUrl: 'partials/store/server/', controller: 'StoreServerCtrl'

    $routeProvider.when '/storage',
        templateUrl: 'partials/storage/', controller: 'StorageCtrl'

    $routeProvider.when '/storage/:server',
        templateUrl: 'partials/storage/server/', controller: 'StorageServerCtrl'


app.factory 'Player', ($resource) ->
    $resource '/api/v1/player/:action', {},
        login: {method:'post', params:{action:'login'}}
        logout: {method:'post', params:{action:'logout'}}


app.factory 'PlayerPayment', ($resource) ->
    $resource '/api/v1/player/payments/:paymentId', {paymentId:'@id'},
        query: {method:'GET', isArray:true, cache:true}
        create: {method:'POST'}


app.factory 'Subscription', ($resource) ->
    $resource '/api/v1/player/subscriptions/:subscriptionId/:action', {subscriptionId:'@id'},
        query: {method:'GET', isArray:true, cache:true}
        subscribe: {method:'POST', params:{action:'subscribe'}}

app.controller 'IndexRouteCtrl', ($scope, $route) ->
    $scope.state= 'ready'

app.controller 'PlayerRouteCtrl', ($scope, $route, Player, subscriptionList) ->
    $scope.state= 'ready'

    $scope.subscriptions= subscriptionList
    $scope.subscribe= (subscription) ->
        console.log 'подписаться', subscription
        subscription.$subscribe () ->
                console.log 'подписался'
        ,   () ->
                console.log 'не удалось подписаться'

app.controller 'PlayerPaymentCreateCtrl', ($scope, $location, PlayerPayment, $log) ->
    $scope.payment= new PlayerPayment
    $scope.create= () ->
        $log.info 'Заплатить'
        $scope.payment.$create (payment) ->
                $log.info 'запись о пополнении создана'
                do $scope.hideDialog
                $location.path "/payments/#{payment.id}"
        ,   () ->
                $log.error 'запись о пополнении не создана'


app.controller 'PlayerPaymentListCtrl', ($scope, PlayerPayment, $log) ->
    $scope.state= null
    $scope.payments= PlayerPayment.query () ->
        $scope.state= 'ready'

app.controller 'PlayerPaymentCtrl', ($scope, $routeParams, PlayerPayment, $log) ->
    $scope.state= null
    $scope.payment= PlayerPayment.get $routeParams, () ->
        $scope.state= 'ready'


app.factory 'ServerStore', ($resource) ->
    $resource '/api/v1/servers/:serverId/store', {serverId:'@id'},
        get: {method:'GET', cache:true, params:{serverId:'@id'}}

app.factory 'ServerStoreItem', ($resource) ->
    $resource '/api/v1/store/servers/:serverId/items/:itemId/:action'
    ,   {serverId:'@serverId', itemId:'@itemId'}
    ,
        order: {method:'POST', params:{action:'order'}}


app.factory 'Server', ($resource) ->
    $resource '/api/v1/servers/:serverId', {serverId:'@id'},
        query: {method:'GET', cache:true, isArray:true}

app.factory 'ServerStorage', ($resource) ->
    $resource '/api/v1/servers/:serverId/storage', {serverId:'@id'},
        get: {method:'GET', cache:true, params:{serverId:'@id'}}

app.factory 'ServerStorageItem', ($resource) ->
    $resource '/api/v1/storage/servers/:serverId/items/:itemId/:action'
    ,   {serverId:'@serverId', itemId:'@itemId'}
    ,
        order: {method:'POST', params:{action:'order'}}


app.controller 'ViewCtrl', ($scope, $rootScope, $location, $window, Player, Server, $log) ->

    $rootScope.player= Player.get () ->
        $log.info 'игрок получен'

    $rootScope.logout= () ->
        $rootScope.player.$logout () ->
            $window.location.href= '/'

    $rootScope.servers= Server.query ->
        $log.info 'список серверов получен'

    $rootScope.getServerByName= (name) ->
        for server in $rootScope.servers
            return server if server.name == name

    $rootScope.store=
        servers: Server.query ->
            $log.info 'список серверов получен'


    $rootScope.dialog=
        overlay: null

    $rootScope.showDialog= (type) ->
        $rootScope.dialog.overlay= type or true

    $rootScope.hideDialog= () ->
        $rootScope.dialog.overlay= null

    $scope.showPayDialog= () ->
        $scope.showDialog 'pay'




app.controller 'PlayerCtrl', ($scope, $route, Player) ->
    $scope.player= Player.get () ->
            $scope.state= 'ready'
    ,   (err) ->
            $scope.state= 'error'
            $scope.error=
                error: err
                title: 'Не удалось загрузить пользователя'





app.controller 'StoreCtrl', ($scope, $rootScope, $q, $log) ->
    $scope.state= null

    $scope.server= null

    promise= $q.all
        player: $rootScope.player.$promise
        servers: $rootScope.servers.$promise
    promise.then (resources) ->
            $log.info 'resolved', resources
            $scope.state= 'ready'
    ,   (error) ->
            $scope.state= 'error'


app.controller 'StorageCtrl', ($scope, $rootScope, $q, $log) ->
    $scope.server= null

    $scope.state= null

    promise= $q.all
        player: $rootScope.player.$promise
        servers: $rootScope.servers.$promise
    promise.then (resources) ->
            $log.info 'resolved', resources
            $scope.state= 'ready'
    ,   (error) ->
            $scope.state= 'error'


app.controller 'StorageServerCtrl', ($scope, $rootScope, $q, $routeParams, ServerStorage, $log) ->
    $scope.state= null

    $scope.storage= null

    promise= $q.all
        player: $rootScope.player.$promise
        servers: $rootScope.servers.$promise
    promise.then (resources) ->
            $log.info 'resolved', resources
            server= $rootScope.server= $rootScope.getServerByName $routeParams.server
            console.log 'root server', server
            ServerStorage.get
                serverId: server.id
            ,   (storage) ->
                    $log.info 'resolved storage', storage
                    $scope.storage= $rootScope.server.storage= storage
                    $scope.state= 'ready'
    ,   (error) ->
            $scope.state= 'error'


app.controller 'StoreServerCtrl', ($scope, $rootScope, $q, $routeParams, ServerStore, $log) ->
    $scope.state= null

    console.log 'store server'

    promise= $q.all
        player: $rootScope.player.$promise
        servers: $scope.store.servers.$promise
    promise.then (res) ->
            $log.info 'resolved', res
            server= $rootScope.server= $rootScope.getServerByName $routeParams.server
            ServerStore.get
                serverId: server.id
            ,   (store) ->
                    $log.info 'resolved store', store
                    $scope.store= store
                    $scope.state= 'ready'
    ,   (error) ->
            $scope.state= 'error'





app.controller 'StoreServerItemCtrl', ($scope, $rootScope) ->

    $scope.showItemDetails= () ->
        $rootScope.item= $scope.item
        $scope.showDialog 'item'





app.filter 'EnchantmentLevel', () ->
    getEnchantmentDisplayLevel= (eid, level) ->
        switch eid
            when '0' # защита
                return 'I' if level < 22
                return 'II' if 21 < level < 33
                return 'III' if 32 < level < 44
                return 'IV' if 43 < level
            when '1' # огнестойкость
                return 'I' if level < 23
                return 'II' if 22 < level < 31
                return 'III' if 30 < level < 39
                return 'IV' if 38 < level
            when '2' # легкость
                return 'I' if level < 16
                return 'II' if 15 < level < 22
                return 'III' if 21 < level < 28
                return 'IV' if 27 < level
            when '3' # взрывоустойчивость
                return 'I' if level < 18
                return 'II' if 17 < level < 26
                return 'III' if 25 < level < 34
                return 'IV' if 33 < level
            when '4' # снарядостойкость
                return 'I' if level < 19
                return 'II' if 18 < level < 25
                return 'III' if 24 < level < 31
                return 'IV' if 30 < level
            when '5' # дыхание
                return 'I' if level < 41
                return 'II' if 40 < level < 51
                return 'III' if 50 < level
            when '6' # родство с водой
                return 'I'
            when '7' # шипы
                return 'I' if level < 61
                return 'II' if 60 < level < 81
                return 'III' if 80 < level
            when '16' # острота
                return 'I' if level < 22
                return 'II' if 21 < level < 33
                return 'III' if 32 < level < 44
                return 'IV' if 43 < level < 55
                return 'V' if 54 < level
            when '17' # небесная кара
                return 'I' if level < 26
                return 'II' if 25 < level < 34
                return 'III' if 33 < level < 42
                return 'IV' if 41 < level < 50
                return 'V' if 49 < level
            when '18' # бич членистоногих
                return 'I' if level < 26
                return 'II' if 25 < level < 34
                return 'III' if 33 < level < 42
                return 'IV' if 41 < level < 50
                return 'V' if 49 < level
            when '19' # отбрасывание
                return 'I' if level < 56
                return 'II' if 55 < level
            when '20' # аспект огня
                return 'I' if level < 61
                return 'II' if 60 < level
            when '21' # мародерство
                return 'I' if level < 66
                return 'II' if 65 < level < 75
                return 'III' if 74 < level
            when '48' # сила
                return 'I' if level < 17
                return 'II' if 16 < level < 27
                return 'III' if 26 < level < 37
                return 'IV' if 36 < level < 47
                return 'V' if 46 < level
            when '49' # ударная волна
                return 'I' if level < 38
                return 'II' if 38 < level
            when '50' # воспламенение
                return 'I'
            when '51' # бесконечность
                return 'I'
            when '32' # эффективность
                return 'I' if level < 52
                return 'II' if 51 < level < 62
                return 'III' if 61 < level < 72
                return 'IV' if 71 < level < 82
                return 'V' if 81 < level
            when '33' # шелковое касание
                return 'I'
            when '34' # неразрушимость
                return 'I' if level < 56
                return 'II' if 55 < level < 64
                return 'III' if 63 < level
            when '35' # удача
                return 'I' if level < 66
                return 'II' if 65 < level < 75
                return 'III' if 74 < level
    return (ench) ->
        return getEnchantmentDisplayLevel ench.id, ench.level


app.controller 'StoreServerItemDetailsCtrl', ($scope, $rootScope, ServerStoreItem) ->
    $scope.item= new ServerStoreItem angular.copy $scope.item
    $scope.itemPrice= $scope.item.price

    $scope.updatePrice= (price) ->
        $scope.item.price = $scope.item.price + price

    $scope.restrict= (item) ->
        return (enchantment) ->
            for ench in item.enchantments
                if enchantment.id == ench.id
                    return false
            return enchantment

    $scope.addEnchantment= (ench) ->
        for enchantment in $scope.item.enchantments
            if enchantment.id == ench.id
                return
        $scope.item.enchantments.push ench= angular.copy ench
        ench.level= ench.levelMin or 0
        ench.removable= true

    $scope.remEnchantment= (ench, price) ->
        i= $scope.item.enchantments.indexOf ench
        if i > -1
            $scope.item.enchantments.splice i, 1
            $scope.updatePrice 0 - price

    $scope.orderState= 'none'
    $scope.order= (item) ->
        console.log 'order', item
        $scope.orderState= 'pending'
        order=
            serverId: $scope.server.id
            itemId: item.id
            item: item
        ServerStoreItem.order order, () ->
                console.log 'получилось'
                $scope.orderState= 'done'
        ,   () ->
                console.log 'не получилось'
                $scope.orderState= 'fail'




app.controller 'StoreServerItemDetailsEnchCtrl', ($scope, $rootScope) ->

    calcXpForLevel= (pLevel) ->
        if 17 > pLevel
            return 17 * pLevel
        if 16 < pLevel and 32 > pLevel
            return (1.5 * (pLevel * pLevel)) - (29.5 * pLevel) + 360
        if 31 < pLevel
            return (3.5 * (pLevel * pLevel)) - (151.5 * pLevel) + 2220

    calcXpForEnchantment= (eLevel, enchantability) ->
        pLevel= Math.floor eLevel - (1 + (enchantability / 2))
        return calcXpForLevel Math.max 1, pLevel

    $scope.level= 0
    $scope.levelMin= 0
    $scope.levelMax= 127

    $scope.xp= 0
    $scope.xpMin= 0

    $scope.price= 0

    if not $scope.ench.removable
        $scope.levelMin= $scope.ench.level
        $scope.level= $scope.levelMin
        $scope.xpMin= calcXpForEnchantment $scope.level, 10
        $scope.xp= $scope.xpMin
        #console.log 'чары входят в стоимость, levelMin: %d, xp: %d. Цена: %d', $scope.levelMin, $scope.xp, $scope.xp - $scope.xpMin
    else
        $scope.levelMin= $scope.ench.levelMin or 1
        $scope.level= $scope.ench.level or $scope.levelMin
        $scope.xp= calcXpForEnchantment $scope.level, 10
        #console.log 'чары не входят в стоимость, levelMin: %d, level: %d, xp: %d. Цена: %d', $scope.levelMin, $scope.level, $scope.xp, $scope.xp - $scope.xpMin

    $scope.levelMax= $scope.ench.levelMax

    $scope.$watch 'price', (newVal, oldVal) ->
        $scope.updatePrice newVal - oldVal

    $scope.$watch 'level', (level, o) ->
        if level < $scope.levelMin
            $scope.level= $scope.levelMin
            return
        $scope.xp= (calcXpForEnchantment level, 10) - $scope.xpMin
        #console.log 'обновился уровень чар: %d, разница xp: %d', level, $scope.xp
        $scope.ench.level= $scope.level

        $scope.price= $scope.xp * 0.03
