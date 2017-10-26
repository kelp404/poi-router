angular.module 'poi.view', []

.directive 'poiView', ['$injector', ($injector) ->
    $router = $injector.get '$router'
    $rootScope = $injector.get '$rootScope'
    $location = $injector.get '$location'
    $compile = $injector.get '$compile'
    $controller = $injector.get '$controller'

    onClickLink = (event) ->
        if event.ctrlKey or event.metaKey or event.shiftKey or event.which is 2 or event.button is 2
            return
        target = event.target.target
        href = event.target.href
        return if target or not href
        if $location.absUrl() is href
            # reload
            event.preventDefault()
            $rootScope.$apply ->
                $router.reload yes

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
                    if @rule.parents.length is 1
                        $element.off 'click', 'a', onClickLink
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
                $element.html rule.template
                $compile($element.contents()) @scope
                if rule.parents.length is 1
                    $element.on 'click', 'a', onClickLink
            destroy: ->
                return if not @rule
                if @rule.parents.length is 1
                    $element.off 'click', 'a', onClickLink
                @scope.$destroy()
                @scope = null
                @rule = null
                $element.html ''
]
