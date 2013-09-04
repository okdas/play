app= angular.module 'app', ['ngResource', 'ngRoute'], ($routeProvider) ->

    $routeProvider.when '/',
        templateUrl: 'partials/login/', controller: 'WelcomeCtrl'

    $routeProvider.when '/registration',
        templateUrl: 'partials/registration/', controller: 'WelcomeRegistrationCtrl'

    $routeProvider.otherwise
        redirectTo: '/'


app.factory 'Player', ($resource) ->
    $resource '/api/v1/player/:action', {},
        login: {method:'post', params:{action:'login'}}


app.controller 'ViewCtrl', ($scope, $rootScope, $location, Player) ->

        $scope.player= new Player

        $rootScope.dialog=
            overlay: null
            templateUrl: null

        $rootScope.showDialog= (name) ->
            $rootScope.dialog.overlay= name or true

        $rootScope.hideDialog= () ->
            $rootScope.dialog.overlay= null
            $rootScope.dialog.templateUrl= null


app.controller 'WelcomeCtrl', ($scope, $rootScope) ->
    $rootScope.showLoginDialog= () ->
        $rootScope.dialog.templateUrl= 'partials/login/dialog/'
        $rootScope.showDialog 'login'

app.controller 'WelcomeRegistrationCtrl', ($scope) ->
    $scope.state= 'ready'


app.controller 'LoginDialogCtrl', ($scope, $window) ->

    $scope.login= () ->
        $scope.player.$login () ->
                $window.location.href= '/'
        ,   () ->
                $scope.player.pass= ''
