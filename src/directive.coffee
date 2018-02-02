angular.module 'poi.directive', []


.directive 'a', ['$injector', ($injector) ->
    $location = $injector.get '$location'
    $router = $injector.get '$router'

    restrict: 'E'
    link: (scope, element, attrs) ->
        return if attrs.target or not attrs.href or attrs.href[0] isnt '/'
        element.on 'click', (event) ->
            if event.ctrlKey or event.metaKey or event.shiftKey or event.which is 2 or event.button is 2
                return
            if $location.url() is attrs.href
                # reload
                event.preventDefault()
                scope.$apply -> $router.reload(yes)
]

.directive 'poiView', ['$injector', ($injector) ->
    $router = $injector.get '$router'
    $compile = $injector.get '$compile'
    $controller = $injector.get '$controller'

    restrict: 'A'
    link: (scope, $element) ->
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
                resolve.$scope = @scope
                if rule.onEnter
                    $injector.invoke rule.onEnter, rule, resolve
                if rule.controller
                    $controller rule.controller, resolve
                $element.html rule.template
                $compile($element.contents()) @scope
            destroy: ->
                return if not @rule
                @scope.$destroy()
                @scope = null
                @rule = null
                $element.html ''
]
