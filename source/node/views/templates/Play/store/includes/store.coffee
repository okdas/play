app= angular.module 'play', ['ngAnimate', 'ngRoute', 'ngResource'], ($routeProvider) ->

    $routeProvider.when '/',
        templateUrl: 'partials/', controller: 'StoreCtrl', resolve:
            serverList: (StoreServer) ->
                serverList= do StoreServer.query
                serverList.$promise

    $routeProvider.when '/servers/:serverId',
        templateUrl: 'partials/servers/', controller: 'StoreServerCtrl'





app.factory 'Player', ($resource) ->
    $resource '/api/v1/player/:action', {},
        login: {method:'post', params:{action:'login'}}
        logout: {method:'post', params:{action:'logout'}}


app.factory 'StoreServer', ($resource) ->
    $resource '/api/v1/store/servers/:serverId', {serverId:'@id'},
        query: {method:'GET', isArray:true, cache:true}
        get: {method:'GET', cache:true, params:{serverId:'@id'}}


app.factory 'StoreServerItem', ($resource) ->
    $resource '/api/v1/store/servers/:serverId/items/:itemId/:action', {serverId:'@serverId', itemId:'@itemId'},
        order: {method:'POST', params:{action:'order'}}





app.controller 'ViewCtrl', ($scope, $rootScope, $location, $window, Player, StoreServer, $log) ->

    $rootScope.player= Player.get () ->

    $rootScope.logout= () ->
        $rootScope.player.$logout () ->
            $window.location.href= '/'


    $rootScope.store=
        servers: StoreServer.query ->
            $log.info 'список серверов получен'


    $rootScope.dialog=
        overlay: null

    $rootScope.showDialog= (type) ->
        $rootScope.dialog.overlay= type or true

    $rootScope.hideDialog= () ->
        $rootScope.dialog.overlay= null





app.controller 'PlayerCtrl', ($scope, $route, Player) ->
    $scope.player= Player.get () ->
            $scope.state= 'ready'
    ,   (err) ->
            $scope.state= 'error'
            $scope.error=
                error: err
                title: 'Не удалось загрузить пользователя'





app.controller 'StoreCtrl', ($scope, serverList) ->
    $scope.state= 'ready'
    $scope.store=
        servers: serverList





app.controller 'StoreServerCtrl', ($scope, $rootScope, $routeParams, $q, StoreServer, StoreServerItem, $log) ->
    $scope.state= null

    $scope.store.server= StoreServer.get $routeParams, ->

    promise= $q.all [
        $rootScope.player.$promise
        $scope.store.servers.$promise
        $scope.store.server.$promise
    ]
    promise.then (resources) ->
            $scope.state= 'ready'
            for server in $scope.store.servers
                if server.id == $scope.store.server.id
                    $scope.cart= server
                    $scope.cart.items= [] if not $scope.cart.items
    ,   (error) ->
            $scope.state= 'error'


    $scope.order= (item) ->
        $log.info 'купить предмет', item
        StoreServerItem.order
            serverId: $scope.store.server.id
            itemId: item.id
            item: item





app.controller 'StoreServerItemCtrl', ($scope, $rootScope) ->
    $scope.amount= 1

    $scope.buyItem= (item) =>
        return if not $scope.amount

        found= null
        for itm in $scope.cart.items
            if not found and itm.id == item.id
                found= itm

        if not found
            found= angular.copy item
            found.amount= 0
            $scope.cart.items.push found

        amount= (found.amount|0) + ($scope.amount|0)
        found.amount= if amount > 99999 then 99999 else amount
        #$scope.amount= 1

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



app.controller 'StoreServerItemDetailsCtrl', ($scope, $rootScope) ->
    $scope.item= angular.copy $scope.item
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





app.controller 'StoreServerItemDetailsEnchCtrl', ($scope, $rootScope) ->

    $scope.ench.levelMin= $scope.ench.level or 1

    $scope.levelMin= $scope.ench.level or $scope.ench.levelMin or 1
    $scope.levelMax= $scope.ench.levelMax

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

    $scope.price= 0

    level= 0
    $scope.xp= 0
    $scope.xpMin= 0
    if not $scope.ench.removable
        level= $scope.ench.level
        $scope.xp= $scope.xpMin= calcXpForEnchantment level, 10

    $scope.$watch 'ench.level', (level, o) ->
        if level < $scope.levelMin
            $scope.ench.level= $scope.levelMin
            return
        $scope.xp= (calcXpForEnchantment level, 10) - $scope.xpMin
        $scope.price= $scope.xp * 0.03

    $scope.$watch 'price', (newVal, oldVal) ->
        $scope.updatePrice newVal - oldVal
