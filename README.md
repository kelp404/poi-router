# poi-router

An AngularJS 1.X router.


## Installation
```bash
$ bower install https://github.com/kelp404/poi-router.git\#v0.0.1 -S
```


## Quick start
**Include poi-router.js at your html**
```html
<script type="text/javascript" src="/bower_components/poi-router/dist/poi-router.js"></script>
```

**Add poi-view element at the base html**
```html
<div poi-view>
    <p style="padding: 20px 0; text-align: center;">Loading...</p>
</div>
```

**Register router rules**
```coffee
angular.module 'your-module.routers', ['poi']

.config ['$routerProvider', ($routerProvider) ->
    $routerProvider.register 'index',
        uri: '/'
        resolve:
            data: ['$http', ($http) ->
                $http(method: 'get', url: '/api/data').then (response) ->
                    response.data
            ]
        templateUrl: '/template/index.html'
        controller: ['$scope', 'data', ($scope, data) ->
            $scope.data = data
        ]
]
```


## Development
```bash
# Install node modules.
$ npm install -g grunt-cli coffee-script nodemon
$ npm install
```

```bash
# Build
$ grunt build
```


## $router
```coffee
$routerProvider.register = (namespace, args={})->
    ###
    Register the router rule.
    @param namespace {string} The name of the rule.
    @param args {object} The router rule.
        abstract: {bool} This is abstract rule, it will render the child rule.
        uri: {string}  ex: '/projects/{projectId:[\w-]{20}}/tests/{testId:(?:[\w-]{20}|initial)}'
        resolve: {object}
        templateUrl: {string}
        controller: {string|function} The controller name or angular function.
        onEnter: {function} It will be executed before the controller.
    ###
```

```coffee
$router.go = (namespace, params, options={}) ->
    ###
    Go to the url.
    @param namespace {string} The namespace of the rule or the url.
    @param params {object} The params of the rule.
    @param options {object}
        replace: {bool}
        reload: {bool}  If it is true, it will reload all views.
    ###
```

```coffee
$router.reload = ->
    ###
    Reload the current rule, this method will not reload parent views.
    ###
```


## Events
**$stateChangeStart**
```coffee
$scope.$on '$stateChangeStart', (event, toState, fromState, cancel) ->
    ###
    @param event {Event}
    @param toState {object}
        name: {string} The rule name.
        params: {object}
    @param fromState {object}
        name: {string} The rule name.
        params: {object}
    @param cancel {function} Call this function to cancel this state change.
    ###
```

**$stateChangeSuccess**
```coffee
$scope.$on '$stateChangeSuccess', (event, toState, fromState) ->
    ###
    @param event {Event}
    @param toState {object}
        name: {string} The rule name.
        params: {object}
    @param fromState {object}
        name: {string} The rule name.
        params: {object}
    ###
```

**$stateChangeError**
```coffee
$scope.$on '$stateChangeError', (event, error) ->
    ###
    @param event {Event}
    @param error {object}
    ###
```


## Example
```coffee
# ---------------------------------------------------------
#
# ---------------------------------------------------------
$routerProvider.register 'web',
    uri: ''
    resolve:
        stores: ['$rootScope', '$admin', ($rootScope, $admin) ->
            $admin.api.store.getMyStores().then (response) ->
                response.data
        ]
    templateUrl: '/views/layout.html'
    controller: ['$scope', 'stores', ($scope, stores) ->
        $scope.stores = stores
    ]
# ---------------------------------------------------------
# /stores/:storeId
# ---------------------------------------------------------
$routerProvider.register 'web.store',
    abstract: yes
    uri: '/stores/{storeId:[\\w-]{20}}'
    resolve:
        store: ['$admin', '$rootScope', 'params', ($admin, $rootScope, params) ->
            $admin.api.store.getStore params.storeId
            .success (store) ->
                $rootScope.$title = store.title
            .then (response) ->
                response.data
        ]
    templateUrl: '/views/stores/store.html'
    controller: 'StoreController'
$routerProvider.register 'web.store.status',
    uri: ''
    onEnter: ['$rootScope', 'store', ($rootScope, store) ->
        $rootScope.$title = "Status - #{store.title}"
    ]
    templateUrl: '/views/stores/status.html'
    controller: 'StoreStatusController'
```
