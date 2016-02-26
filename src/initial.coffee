angular.module 'poi.initial', []

.config ['$locationProvider', ($locationProvider) ->
    # setup html5 mode
    $locationProvider.html5Mode
        enabled: yes
        requireBase: no
]
