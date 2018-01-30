(function() {
  window.NProgress.configure({
    showSpinner: false
  });

  angular.module('app', ['poi']).run([
    '$injector', function($injector) {
      var $rootScope;
      $rootScope = $injector.get('$rootScope');
      $rootScope.$on('$stateChangeStart', function() {
        return window.NProgress.start();
      });
      $rootScope.$on('$stateChangeSuccess', function() {
        return window.NProgress.done();
      });
      return $rootScope.$on('$stateChangeError', function() {
        return window.NProgress.done();
      });
    }
  ]).config([
    '$routerProvider', function($routerProvider) {
      $routerProvider.register('web', {
        uri: '/poi-router',
        templateUrl: '/poi-router/example/templates/layout.html',
        controller: [
          '$scope', '$injector', function($scope, $injector) {
            var $router;
            $router = $injector.get('$router');
            return $scope.$state = $router.state;
          }
        ]
      });
      $routerProvider.register('web.home', {
        uri: '/',
        onEnter: [
          '$rootScope', function($rootScope) {
            return $rootScope.$title = 'Home - poi-router';
          }
        ],
        templateUrl: '/poi-router/example/templates/home.html',
        controller: function() {}
      });
      $routerProvider.register('web.users', {
        uri: '/users/',
        onEnter: [
          '$rootScope', function($rootScope) {
            return $rootScope.$title = 'Users - poi-router';
          }
        ],
        templateUrl: '/poi-router/example/templates/users.html',
        resolve: {
          users: [
            '$http', function($http) {
              return $http({
                method: 'get',
                url: '/poi-router/example/data/users.json'
              }).then(function(response) {
                return response.data;
              });
            }
          ]
        },
        controller: [
          '$scope', 'users', function($scope, users) {
            return $scope.users = users;
          }
        ]
      });
      return $routerProvider.register('web.user', {
        uri: '/users/{userId:[a-f0-9-]{36}}/',
        onEnter: [
          '$rootScope', function($rootScope) {
            return $rootScope.$title = 'User - poi-router';
          }
        ],
        templateUrl: '/poi-router/example/templates/user.html',
        resolve: {
          user: [
            '$http', function($http) {
              return $http({
                method: 'get',
                url: '/poi-router/example/data/user.json'
              }).then(function(response) {
                return response.data;
              });
            }
          ]
        },
        controller: [
          '$scope', 'user', function($scope, user) {
            return $scope.user = user;
          }
        ]
      });
    }
  ]);

}).call(this);
