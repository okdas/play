app= angular.module 'play', ['ngResource', 'ngRoute'], ($routeProvider) ->

    $routeProvider.when '/',
        templateUrl: 'partials/login/', controller: 'LoginCtrl'


app.factory 'Player', ($resource) ->
    $resource '/api/v1/player/:action', {},
        login: {method:'post', params:{action:'login'}}


app.controller 'ViewCtrl', ($scope, $location, Player) ->
        $scope.dialog=
            overlay: null
            templateUrl: 'partials/login/dialog/'

        $scope.player= new Player

        $scope.showDialog= () ->
            $scope.dialog.overlay= true

        $scope.hideDialog= () ->
            $scope.dialog.overlay= null


app.controller 'LoginCtrl', ($scope) ->
    $scope.state= 'loaded'


app.controller 'LoginDialogCtrl', ($scope, $window) ->

    $scope.login= () ->
        $scope.player.$login () ->
                #do $scope.hideDialog
                $window.location.href= '/'
        ,   () ->
                $scope.player.pass= ''
