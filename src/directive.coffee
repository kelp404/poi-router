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
