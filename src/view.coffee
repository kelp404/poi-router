angular.module 'poi.view', []

.directive 'poiView', ['$injector', ($injector) ->
    $rootScope = $injector.get '$rootScope'
    $router = $injector.get '$router'
    $compile = $injector.get '$compile'
    $controller = $injector.get '$controller'

    restrict: 'A'
    link: (scope, element) ->
        $router.registerView
            scope: null
            rule: null
            updateTemplate: (rule, resolve, destroy) ->
                ###
                Update the poi-view
                @param rule {Rule}
                @param resolve {object}
                @param destroy {bool} if it is true, call .$destroy()
                ###
                if destroy
                    @scope?.$destroy()
                else if @rule
                    if $router.oldState.name.indexOf("#{$router.state.name}.") is 0
                        # do not re-render when back to parent.
                        return
                    @scope.$destroy()
                @rule = rule
                @scope = scope.$new()
                if rule.controller
                    resolve.$scope = @scope
                    if rule.onEnter
                        $injector.invoke rule.onEnter, rule, resolve
                    $controller rule.controller, resolve
                $(element).html rule.template
                $compile(element.contents()) @scope
            destroy: ->
                return if not @rule
                @scope.$destroy()
                @scope = null
                @rule = null
                $(element).html ''
]
