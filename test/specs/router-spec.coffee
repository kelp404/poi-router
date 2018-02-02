describe 'poi.router', ->
    fakeModule = null
    routerProvider = null

    beforeEach ->
        fakeModule = angular.module 'fakeModule', ['poi']
        fakeModule.config ($routerProvider) ->
            routerProvider = $routerProvider
        module 'poi'
        module 'fakeModule'

    describe '$router', ->
        it '$router.register() will push the rule object into routerProvider.rules.', inject ($router) ->
            $router.register 'web',
                uri: '/'
                templateUrl: '/template.html'
                controller: 'HomeController'
            routerProvider.rules.web.parents.pop()
            delete routerProvider.rules.web.getCurrentParams
            expect(routerProvider.rules).toEqual
                web:
                    uri: '/'
                    templateUrl: '/template.html'
                    controller: 'HomeController'
                    namespace: 'web'
                    uriParams: []
                    matchPattern: '/'
                    hrefTemplate: '/'
                    parents: []
                    matchReg: /^\/$/

        it 'check getCurrentParams() of $router.register().', inject ($router, $location) ->
            spyOn($location, 'path').and.returnValue '/AWFQ3MSHnmhfNRKX-yO9/?filter=root'
            spyOn($location, 'search').and.returnValue
                filter: 'root'
            $router.register 'web',
                uri: '/{userId:[\\w-]{20}}/?filter'
                templateUrl: '/template.html'
                controller: 'HomeController'
            rule = routerProvider.rules.web
            expect(rule.getCurrentParams()).toEqual
                userId: 'AWFQ3MSHnmhfNRKX-yO9'
                filter: 'root'

        it '$router.registerView() will push the view into views and call renderViews().', inject ($router) ->
            spyOn routerProvider, 'renderViews'
            $router.registerView 'view'
            expect(routerProvider.views[0]).toBe 'view'
            expect(routerProvider.renderViews).toHaveBeenCalled()

        it '$router.go() with url and reload option.', inject ($router, $location) ->
            spyOn $location, 'url'
            $router.go '/home', null, reload: yes
            expect(routerProvider.isReloadAtThisRender).toBeTruthy()
            expect($location.url).toHaveBeenCalledWith '/home'
        it '$router.go() with namespace and replace option.', inject ($router, $location) ->
            spyOn $location, 'path'
            spyOn $location, 'search'
            spyOn $location, 'replace'
            hrefSpy = spyOn routerProvider, 'href'
            hrefSpy.and.returnValue 'href'
            $router.go 'namespace', 'params', replace: yes
            expect(routerProvider.isReloadAtThisRender).toBeFalsy()
            expect(hrefSpy).toHaveBeenCalledWith 'namespace', 'params', {}
            expect($location.path).toHaveBeenCalledWith 'href'
            expect($location.search).toHaveBeenCalledWith {}
            expect($location.replace).toHaveBeenCalled()

        it '$router.reload() will call renderViews()', inject ($router) ->
            spyOn routerProvider, 'renderViews'
            routerProvider.currentRule =
                namespace: 'test'
            $router.reload()
            expect(routerProvider.renderViews).toHaveBeenCalledWith yes, 'test'
        it '$router.reload() with reload parents will call renderViews()', inject ($router) ->
            spyOn routerProvider, 'renderViews'
            $router.reload yes
            expect(routerProvider.renderViews).toHaveBeenCalledWith yes, yes

        it '$router.href() with undefined namespace.', inject ($router) ->
            expect(-> $router.href('undefined')).toThrow new Error('Can\'t find the rule undefined.')
        it '$router.href() without search argument.', inject ($router) ->
            routerProvider.rules =
                home:
                    hrefTemplate: '/{key}'
            result = $router.href 'home',
                key: 'test'
                index: 0
            expect(result).toBe '/test?index=0'
        it '$router.href() with search argument.', inject ($router) ->
            routerProvider.rules =
                home:
                    hrefTemplate: '/{key}'
            search = {}
            result = $router.href 'home', key: 'test', index: 0, search
            expect(result).toBe '/test'
            expect(search).toEqual index: 0

        it '$router.oldState and $routerProvider.oldState are the same object', inject ($router) ->
            expect($router.oldState).not.toBeNull()
            expect($router.oldState).toBe routerProvider.oldState
            expect(typeof($router.oldState)).toBe 'object'
        it '$router.state and $routerProvider.state are the same object', inject ($router) ->
            expect($router.state).not.toBeNull()
            expect($router.state).toBe routerProvider.state
            expect(typeof($router.state)).toBe 'object'
        it '$router.register and $routerProvider.register are the same object', inject ($router) ->
            expect($router.register).not.toBeNull()
            expect($router.register).toBe routerProvider.register
            expect(typeof($router.register)).toBe 'function'
        it '$router.registerView and $routerProvider.registerView are the same object', inject ($router) ->
            expect($router.registerView).not.toBeNull()
            expect($router.registerView).toBe routerProvider.registerView
            expect(typeof($router.registerView)).toBe 'function'
        it '$router.go and $routerProvider.go are the same object', inject ($router) ->
            expect($router.go).not.toBeNull()
            expect($router.go).toBe routerProvider.go
            expect(typeof($router.go)).toBe 'function'
        it '$router.reload and $routerProvider.reload are the same object', inject ($router) ->
            expect($router.reload).not.toBeNull()
            expect($router.reload).toBe routerProvider.reload
            expect(typeof($router.reload)).toBe 'function'
        it '$router.href and $routerProvider.href are the same object', inject ($router) ->
            expect($router.href).not.toBeNull()
            expect($router.href).toBe routerProvider.href
            expect(typeof($router.href)).toBe 'function'
