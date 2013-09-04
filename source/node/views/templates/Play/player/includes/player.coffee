app= angular.module 'play', ['ngAnimate', 'ngRoute', 'ngResource'], ($routeProvider) ->

    $routeProvider.when '/',
        templateUrl: 'partials/', controller: 'PlayerCtrl', resolve:
            subscriptionList: ($q, Subscription) ->
                dfd= do $q.defer
                Subscription.query (subscriptions) ->
                    dfd.resolve subscriptions
                dfd.promise

    $routeProvider.when '/payments',
        templateUrl:'partials/payments/', controller:'PlayerPaymentListCtrl'

    $routeProvider.when '/payments/:paymentId',
        templateUrl: 'partials/payments/payment/', controller:'PlayerPaymentCtrl'


    #$routeProvider.when '/payments/:paymentId',
    #    templateUrl: 'partials/payments/payment/', controller:'PlayerPaymentCtrl'



app.factory '$cache', ($cacheFactory) ->
    $cacheFactory 'play'


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


app.controller 'ViewCtrl', ($scope, $location, $window, Player) ->
    $scope.dialog=
        overlay: null

    $scope.showDialog= () ->
        $scope.dialog.overlay= true

    $scope.hideDialog= () ->
        $scope.dialog.overlay= null

    $scope.view=
        state: null

    $scope.player= Player.get () ->
            $scope.state= 'ready'
    ,   (err) ->
            $scope.state= 'error'
            $scope.error=
                error: err
                title: 'Не удалось загрузить пользователя'

    $scope.showPayDialog= () ->
        $scope.showDialog 'pay'


app.controller 'PlayerCtrl', ($scope, $route, Player, subscriptionList) ->
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
