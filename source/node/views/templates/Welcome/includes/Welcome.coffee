app= angular.module 'app', ['ngResource', 'ngRoute'], ($routeProvider) ->

    $routeProvider.when '/',
        templateUrl: 'partials/', controller: 'WelcomeCtrl'

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
    $scope.state= 'ready'

    $rootScope.showSigninDialog= () ->
        $rootScope.showDialog 'signin'

    $rootScope.showSignupDialog= () ->
        $rootScope.showDialog 'signup'


app.controller 'SigninDialogCtrl', ($scope, $window) ->

    $scope.signin= () ->
        $scope.player.$login () ->
                $window.location.href= '/'
        ,   () ->
                $scope.player.pass= ''

app.controller 'SignupDialogCtrl', ($scope, $window) ->

    $scope.signup= () ->
        $scope.player.$create () ->
                $window.location.href= '/'
        ,   () ->
                $scope.player.pass= ''