angular.module 'poi.router', []

.provider '$router', ->
    # -----------------------------------------------------
    # providers
    # -----------------------------------------------------
    $injector = null
    $rootScope = null
    $http = null
    $templateCache = null
    $q = null
    $window = null
    $location = null


    # -----------------------------------------------------
    # properties
    # -----------------------------------------------------
    @rules = {}  # all rules
    @views = []  # all views. poi-view will call `registerView()` to tell $router.
    @isReloadAtThisRender = no  # true: user call `$router.go {}, {}, reload: yes`
    @resolves = []  # resolve objects. resolved object from all rules
    @oldState = {}
    @state = {}  # current state
    @currentRule = null
    @nextRule = null  # this rule will be render


    # -----------------------------------------------------
    # private methods
    # -----------------------------------------------------
    @setupProvider = (injector) ->
        $injector = injector
        $rootScope = $injector.get '$rootScope'
        $http = $injector.get '$http'
        $templateCache = $injector.get '$templateCache'
        $q = $injector.get '$q'
        $window = $injector.get '$window'
        $location = $injector.get '$location'

        $rootScope.$on '$locationChangeSuccess', =>
            ###
            Listen the event from $location when the location.href was changed.
            ###
            if @currentRule?
                # poi-view will call render at the first time.
                # So we just call renderViews() when @currentRule is not null.
                @renderViews yes, @isReloadAtThisRender
                @isReloadAtThisRender = no

    @renderViews = (locationChanged=no, reload=no, nextRule=null) =>
        ###
        Render views. Fetch templates and resolve objects then bind that on views.
        @param locationChanged {bool} If location was changed, it should be yes.
        @param reload {bool} If it is true, it will re-render all views.
        @param nextRule {rule} direct select the next rule.
        ###
        diffRuleIndex = 0
        isBackToParent = no
        destroyViews = []

        if not @currentRule? and not @nextRule?
            # When @currentRule and @nextRule are null, it mean this is first render.
            # We should set @nextRule by current url.
            @nextRule = nextRule ? @findRuleByUri $location.path()
        else if reload
            if typeof(reload) is 'string'
                for view, index in @views when view.rule.namespace is reload
                    @views.splice index + 1
                    @resolves.splice index - 1
                    diffRuleIndex = index
                    break
                @nextRule = nextRule ? @findRuleByUri $location.path()
            else
                if @views.length
                    @views.splice 1
                if @resolves.length
                    @resolves.splice 0
                @nextRule = nextRule ? @findRuleByUri $location.path()
        else if locationChanged
            @nextRule = nextRule ? @findRuleByUri $location.path()
            # removed different views and resolved objects
            diffRuleIndex = @nextRule.parents.length - 1
            isBackToParent = @currentRule.namespace.indexOf("#{@nextRule.namespace}.") is 0
            for rule, index in @nextRule.parents
                oldRule = @currentRule.parents[index]
                isParamsDifferent = =>
                    ###
                    Are the params different?
                    ###
                    for paramKey, paramValue of rule.getCurrentParams()
                        if @state.params[paramKey] isnt paramValue
                            return yes
                    no

                if not oldRule or oldRule.namespace isnt rule.namespace
                    diffRuleIndex = index
                    isBackToParent = no if isParamsDifferent()
                    break
                if isParamsDifferent()
                    isBackToParent = no
                    diffRuleIndex = index
                    break
            if diffRuleIndex < @views.length
                destroyViews = @views.splice diffRuleIndex + if isBackToParent then 1 else 0
            if diffRuleIndex < @resolves.length
                @resolves.splice diffRuleIndex + if isBackToParent then 1 else 0
        else if not @nextRule? or @views.length > @nextRule.parents.length
            # maybe there is a `poi-view` at the template but there are no rules
            return

        stepStartChange = (cancel) =>
            ###
            Call this method when the render flow was started.
            ###
            $rootScope.$broadcast '$stateChangeStart', @generateStateObject(@nextRule), @state, cancel
        stepChanging = =>
            ###
            Call this method when the resolve objects was done.
            ###
            @updateOldState @state
            @updateState @generateStateObject(@nextRule)
        stepCompletedChange = =>
            ###
            Call this method when the finial render was done.
            ###
            @currentRule = @nextRule
            @nextRule = null
            $rootScope.$broadcast '$stateChangeSuccess', @state, @oldState
        stepChangeError = (error) =>
            $rootScope.$broadcast '$stateChangeError', error

        if (not @currentRule? and @views.length is 1) or locationChanged
            # (@currentRule==null and @views.length is 1) -> for the first render
            # start render
            tasks = []  # all promise to fetch resource
            for ruleIndex in [diffRuleIndex...@nextRule.parents.length] by 1
                rule = @nextRule.parents[ruleIndex]
                do (rule) =>
                    if not isBackToParent or ruleIndex isnt diffRuleIndex
                        tasks.push @fetchResolve(rule).then (result) =>
                            @resolves[rule.parents.length - 1] = result
                    if rule.templateUrl
                        tasks.push @fetchTemplate(rule.templateUrl).success (result) ->
                            rule.template = result
            cancel = no
            stepStartChange -> cancel = yes
            if cancel
                for destroyView in destroyViews
                    @views.push destroyView
                stepChanging()
                return
            $q.all(tasks).then =>
                stepChanging()
                if destroyViews.length
                    destroyViews[0].destroy()  # clean html of poi-view
                    @views.push destroyViews[0]
                isFinialView = (@nextRule.parents.length - 1) is diffRuleIndex
                @views[diffRuleIndex].updateTemplate @nextRule.parents[diffRuleIndex], @flattenResolve(@resolves.slice(0, diffRuleIndex + 1)), reload
                stepCompletedChange() if isFinialView
            , (error) =>
                for destroyView in destroyViews
                    @views.push destroyView
                stepChanging()
                stepChangeError error
                @renderViews yes, yes, @findErrorHandlerRule()
        else
            # compile view after poi-view was linked
            index = @views.length - 1
            isFinialView = (@nextRule.parents.length - 1) is index
            @views[index].updateTemplate @nextRule.parents[index], @flattenResolve(@resolves.slice(0, index + 1))
            stepCompletedChange() if isFinialView

    @findRuleByUri = (uri) =>
        ###
        Find the rule of the uri.
        @param uri {string}
        ###
        for ruleName, rule of @rules when rule.matchReg.test(uri) and not rule.abstract
            return rule
        null
    @findErrorHandlerRule = =>
        ###
        Find the name of rule that is 'error'.
        ###
        for ruleName, rule of @rules when ruleName is 'error'
            return rule
        null

    @flattenResolve = (resolves) ->
        ###
        Get the resolved object from resolves of all rules.
        @param resolves {list} @resolves
        @returns {object}
        ###
        result = {}
        for resolve in resolves
            for key, value of resolve
                result[key] = value
        result
    @fetchResolve = (rule) =>
        ###
        Fetch resolve objects.
        @param rule {object} The rule object.
        @returns {$q}
        ###
        params = rule.getCurrentParams()
        tasks = []
        resolve = {}
        for key, func of rule.resolve
            do (key, func) ->
                # function invoke(fn, self, locals, serviceName)
                tasks.push $q.all([$injector.invoke(func, rule, params: params)]).then (result) ->
                    resolve[key] = result[0]
        $q.all(tasks).then -> resolve
    @fetchTemplate = (templateUrl) =>
        ###
        Fetch template.
        @param templateUrl {string}
        @returns {$http}
        ###
        $http
            method: 'get'
            url: templateUrl
            cache: $templateCache
            headers:
                Accept: 'text/html'

    @generateStateObject = (rule) =>
        ###
        Generate state object.
        @param rule {object} The rule object.
        @returns {object}
            name: {string}
            params: {object}
        ###
        name: rule.namespace
        params: rule.getCurrentParams()

    @updateOldState = (state={}) =>
        ###
        Update $router.oldState by the state object.
        @param state {object}
        ###
        @oldState.name = state.name
        @oldState.params = state.params
    @updateState = (state) =>
        ###
        Update $router.state by the state object.
        @param state {object}
        ###
        @state.name = state.name
        @state.params = state.params

    # -----------------------------------------------------
    # public methods
    # -----------------------------------------------------
    @register = (namespace, args={}) =>
        ###
        Register the router rule.
        @param namespace {string} The name of the rule.
        @param args {object} The router rule.
            uri: {string}  ex: '/projects/{projectId:[\w-]{20}}/tests/{testId:(?:[\w-]{20}|initial)}'
            resolve: {object}
            templateUrl: {string}
            controller: {string|list|function}
            # ---- generate by register
            namespace: {string}
            uriParams: {list}  ex: ['projectId', '?index']
            matchPattern: {string}  ex: '/projects/([\w-]{20})'
            matchReg: {RegExp} The regexp for .match()  ex: /^\/projects\/([\w-]{20})$/
            hrefTemplate: {string} The template for generating href.  ex: '/projects/{projectId}'
            getCurrentParams: {function}
            parents: {list}
        ###
        # set default value
        args.namespace = namespace
        args.uri ?= ''
        args.template = '<div></div>' if not args.templateUrl

        if namespace.indexOf('.') > 0
            # there are parents for this rule
            parentRule = @rules[namespace.substr(0, namespace.lastIndexOf('.'))]
            args.uriParams = parentRule.uriParams.slice()
            args.matchPattern = parentRule.matchPattern
            args.hrefTemplate = parentRule.hrefTemplate
            args.parents = parentRule.parents.slice()
            args.parents.push args
        else
            # this is a root rule
            args.uriParams = []
            args.matchPattern = ''
            args.hrefTemplate = ''
            args.parents = [args]
        uriParamPatterns = args.uri.match /\{[\w]+:(?:(?!\/).)+/g  # ex: '{projectId:[\w-]{20}}'
        ruleUri = args.uri
        hrefTemplate = args.uri
        for uriParamPattern in uriParamPatterns ? []
            match = uriParamPattern.match /^\{([\w]+):((?:(?!\/).)*)\}$/
            args.uriParams.push match[1]
            ruleUri = ruleUri.replace uriParamPattern, "(#{match[2]})"
            hrefTemplate = hrefTemplate.replace uriParamPattern, "{#{match[1]}}"
        for uriQueryString in args.uri.match(/\?[\w-]+/g) ? []
            ruleUri = ruleUri.replace uriQueryString, ''
            hrefTemplate = hrefTemplate.replace uriQueryString, ''
            args.uriParams.push uriQueryString
        args.matchPattern += ruleUri
        args.matchReg = new RegExp("^#{args.matchPattern}$")
        args.hrefTemplate += hrefTemplate
        args.getCurrentParams = ->
            ###
            Get params from uri and query string via $location.
            @returns {object}
            ###
            result = {}
            match = $location.path().match new RegExp("^#{args.matchPattern}")
            uriParamsIndex = 0
            for param in args.uriParams
                if param.indexOf('?') is 0
                    param = param.substr(1)
                    result[param] = $location.search()[param]
                else
                    result[param] = match[++uriParamsIndex]
            result

        # put the rule into @rules
        @rules[namespace] = args

    @registerView = (view) =>
        ###
        Register the view. `poi-view` should call this method when link.
        @param view {object}
            updateTemplate: {function}
            destroy: {function}
        ###
        @views.push view
        @renderViews()

    @go = (namespace, params, options={}) =>
        ###
        Go to the url.
        @param namespace {string} The namespace of the rule.
        @param params {object} The params of the rule.
        @param options {object}
            replace: {bool}
            reload: {bool}  If it is true, it will reload all views.
        ###
        @isReloadAtThisRender = options.reload
        search = {}
        $location.path @href(namespace, params, search)
        $location.search search
        $location.replace() if options.replace

    @reload = =>
        ###
        Reload the current rule, this method will not reload parent views.
        ###
        @renderViews yes, @currentRule.namespace

    @href = (namespace, params={}, search) =>
        ###
        Generate the href by namespace and params.
        @param namespace {string} The namespace of the rule.
        @param params {object} The params of the rule.
        @param search {object|null} If it is an object, query string will appended at here, else append query string at href.
        @returns {string} The url.
        ###
        rule = @rules[namespace]
        if not rule
            throw new Error("Can't find the rule #{namespace}.")
        href = rule.hrefTemplate
        usedKey = []
        for paramKey, paramValue of params when href.indexOf("{#{paramKey}}") >= 0
            href = href.replace "{#{paramKey}}", encodeURIComponent(paramValue)
            usedKey.push paramKey
        if search?
            for paramKey, paramValue of params when paramKey not in usedKey
                search[paramKey] = paramValue
        else
            queryString = []
            for paramKey, paramValue of params when paramKey not in usedKey
                queryString.push "#{encodeURIComponent(paramKey)}=#{encodeURIComponent(paramValue)}"
            if queryString.length
                href += "?#{queryString.join('&')}"
        href


    # -----------------------------------------------------
    # $get
    # -----------------------------------------------------
    @$get = ['$injector', ($injector) =>
        @setupProvider $injector

        oldState: @oldState
        state: @state
        register: @register
        registerView: @registerView
        go: @go
        reload: @reload
        href: @href
    ]
    return
