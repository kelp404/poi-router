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
