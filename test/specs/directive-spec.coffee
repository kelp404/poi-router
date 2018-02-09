describe 'poi.directive', ->
    $ = angular.element
    $compile = null
    $timeout = null
    $rootScope = null
    $scope = null

    beforeEach ->
        module 'poi'
        inject ($injector) ->
            $compile = $injector.get '$compile'
            $timeout = $injector.get '$timeout'
            $rootScope = $injector.get '$rootScope'
            $scope = $rootScope.$new()

    describe 'a', ->
        it 'check a directive will trigger $router.reload()', inject ($router) ->
            spyOn $router, 'reload'
            $element = $ """<a href="/">Home</a>"""
            $compile($element) $scope
            $rootScope.$digest()
            $element.triggerHandler 'click'
            expect($router.reload).toHaveBeenCalledWith yes

        it 'check a directive will not trigger $router.reload() with meta key', inject ($router) ->
            spyOn $router, 'reload'
            $element = $ """<a href="/">Home</a>"""
            $compile($element) $scope
            $rootScope.$digest()
            $element.triggerHandler
                type: 'click'
                metaKey: yes
            expect($router.reload).not.toHaveBeenCalled()

        it 'check a directive with target attribute will not trigger $router.reload()', inject ($router) ->
            spyOn $router, 'reload'
            $element = $ """<a href="/" target="_blank">Home</a>"""
            $compile($element) $scope
            $rootScope.$digest()
            $element.triggerHandler 'click'
            expect($router.reload).not.toHaveBeenCalled()

        it 'check a directive with empty href will not trigger $router.reload()', inject ($router) ->
            spyOn $router, 'reload'
            $element = $ """<a>Home</a>"""
            $compile($element) $scope
            $rootScope.$digest()
            $element.triggerHandler 'click'
            expect($router.reload).not.toHaveBeenCalled()

        it 'check a directive with sharp href will not trigger $router.reload()', inject ($router) ->
            spyOn $router, 'reload'
            $element = $ """<a href="#logout">Home</a>"""
            $compile($element) $scope
            $rootScope.$digest()
            $element.triggerHandler 'click'
            expect($router.reload).not.toHaveBeenCalled()

    describe 'poiView', ->
        it 'check poi-view will call $router.registerView().', inject ($router) ->
            spyOn $router, 'registerView'
            $element = $ '<div poi-view></div>'
            $compile($element) $scope
            $rootScope.$digest()
            expect($router.registerView).toHaveBeenCalled()
