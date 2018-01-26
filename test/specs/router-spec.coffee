describe 'poi.router', ->
    fakeModule = null
    routerProvider = null

    beforeEach module('poi')
    beforeEach ->
        fakeModule = angular.module 'fakeModule', ['poi']
        fakeModule.config ($routerProvider) ->
            routerProvider = $routerProvider
    beforeEach module('fakeModule')


    describe '$router', ->
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
