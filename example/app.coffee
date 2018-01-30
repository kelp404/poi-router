# setup NProgress
window.NProgress.configure
    showSpinner: no

angular.module 'app', ['poi']

.run ['$injector', ($injector) ->
    $rootScope = $injector.get '$rootScope'

    $rootScope.$on '$stateChangeStart', ->
        window.NProgress.start()
    $rootScope.$on '$stateChangeSuccess', ->
        window.NProgress.done()
    $rootScope.$on '$stateChangeError', ->
        window.NProgress.done()
]

.config ['$routerProvider', ($routerProvider) ->
    # ---------------------------------------------------------
    # /poi-router
    # ---------------------------------------------------------
    $routerProvider.register 'web',
        uri: '/poi-router'
        templateUrl: '/poi-router/example/templates/layout.html'
        controller: ['$scope', '$injector', ($scope, $injector) ->
            $router = $injector.get '$router'
            $scope.$state = $router.state
        ]

    # ---------------------------------------------------------
    # /poi-router/
    # ---------------------------------------------------------
    $routerProvider.register 'web.home',
        uri: '/'
        onEnter: ['$rootScope', ($rootScope) ->
            $rootScope.$title = 'Home - poi-router'
        ]
        templateUrl: '/poi-router/example/templates/home.html'
        controller: ->

    # ---------------------------------------------------------
    # /poi-router/users/
    # ---------------------------------------------------------
    $routerProvider.register 'web.users',
        uri: '/users/'
        onEnter: ['$rootScope', ($rootScope) ->
            $rootScope.$title = 'Users - poi-router'
        ]
        templateUrl: '/poi-router/example/templates/users.html'
        resolve:
            users: ['$http', ($http) ->
                $http
                    method: 'get'
                    url: '/poi-router/example/data/users.json'
                .then (response) -> response.data
            ]
        controller: ['$scope', 'users', ($scope, users) ->
            $scope.users = users
        ]

    # ---------------------------------------------------------
    # /poi-router/users/:userId/
    # ---------------------------------------------------------
    $routerProvider.register 'web.user',
        uri: '/users/{userId:[a-f0-9-]{36}}/'
        onEnter: ['$rootScope', ($rootScope) ->
            $rootScope.$title = 'User - poi-router'
        ]
        templateUrl: '/poi-router/example/templates/user.html'
        resolve:
            user: ['$http', ($http) ->
                $http
                    method: 'get'
                    url: '/poi-router/example/data/user.json'
                .then (response) -> response.data
            ]
        controller: ['$scope', 'user', ($scope, user) ->
            $scope.user = user
        ]
]
