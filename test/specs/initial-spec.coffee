describe 'poi.initial', ->
    it 'Initial module will setup $locationProvider.html5Mode.', ->
        locationProvider = null
        routerProvider = null

        locationModule = angular.module 'locationModule', []
        locationModule.config ($locationProvider) ->
            locationProvider = $locationProvider
            spyOn locationProvider, 'html5Mode'

        fakeModule = angular.module 'fakeModule', ['poi']
        fakeModule.config ($routerProvider) ->
            routerProvider = $routerProvider

        module 'locationModule'
        module 'poi'
        module 'fakeModule'

        inject ($router) ->
            expect(locationProvider.html5Mode).toHaveBeenCalledWith
                enabled: yes
                requireBase: no
