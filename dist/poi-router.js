(function() {
  angular.module('poi.directive', []).directive('a', [
    '$injector', function($injector) {
      var $location, $router;
      $location = $injector.get('$location');
      $router = $injector.get('$router');
      return {
        restrict: 'E',
        link: function(scope, element, attrs) {
          if (attrs.target || !attrs.href || attrs.href[0] !== '/') {
            return;
          }
          return element.on('click', function(event) {
            if (event.ctrlKey || event.metaKey || event.shiftKey || event.which === 2 || event.button === 2) {
              return;
            }
            if ($location.url() === attrs.href) {
              event.preventDefault();
              return scope.$apply(function() {
                return $router.reload(true);
              });
            }
          });
        }
      };
    }
  ]);

}).call(this);

(function() {
  angular.module('poi.initial', []).config([
    '$locationProvider', function($locationProvider) {
      return $locationProvider.html5Mode({
        enabled: true,
        requireBase: false
      });
    }
  ]);

}).call(this);

(function() {
  angular.module('poi', ['poi.directive', 'poi.initial', 'poi.router', 'poi.view']);

}).call(this);

(function() {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  angular.module('poi.router', []).provider('$router', function() {
    var $http, $injector, $location, $q, $rootScope, $templateCache, $window;
    $injector = null;
    $rootScope = null;
    $http = null;
    $templateCache = null;
    $q = null;
    $window = null;
    $location = null;
    this.rules = {};
    this.views = [];
    this.isReloadAtThisRender = false;
    this.resolves = [];
    this.oldState = {};
    this.state = {};
    this.currentRule = null;
    this.nextRule = null;
    this.setupProvider = function(injector) {
      $injector = injector;
      $rootScope = $injector.get('$rootScope');
      $http = $injector.get('$http');
      $templateCache = $injector.get('$templateCache');
      $q = $injector.get('$q');
      $window = $injector.get('$window');
      $location = $injector.get('$location');
      return $rootScope.$on('$locationChangeSuccess', (function(_this) {
        return function() {

          /*
          Listen the event from $location when the location.href was changed.
           */
          if (_this.currentRule != null) {
            _this.renderViews(true, _this.isReloadAtThisRender);
            return _this.isReloadAtThisRender = false;
          }
        };
      })(this));
    };
    this.renderViews = (function(_this) {
      return function(locationChanged, reload, nextRule) {
        var cancel, destroyView, destroyViews, diffRuleIndex, fn, i, index, isBackToParent, isFinialView, isParamsDifferent, j, k, l, len, len1, len2, oldRule, ref, ref1, ref2, ref3, rule, ruleIndex, stepChangeError, stepChanging, stepCompletedChange, stepStartChange, tasks, view;
        if (locationChanged == null) {
          locationChanged = false;
        }
        if (reload == null) {
          reload = false;
        }
        if (nextRule == null) {
          nextRule = null;
        }

        /*
        Render views. Fetch templates and resolve objects then bind that on views.
        @param locationChanged {bool} If location was changed, it should be yes.
        @param reload {bool|string} If it is true, it will re-render all views. string: reload the namespace.
        @param nextRule {rule} direct select the next rule.
         */
        diffRuleIndex = 0;
        isBackToParent = false;
        destroyViews = [];
        if ((_this.currentRule == null) && (_this.nextRule == null)) {
          _this.nextRule = nextRule != null ? nextRule : _this.findRuleByUri($location.path());
        } else if (reload) {
          if (typeof reload === 'string') {
            ref = _this.views;
            for (index = i = 0, len = ref.length; i < len; index = ++i) {
              view = ref[index];
              if (!(view.rule.namespace === reload)) {
                continue;
              }
              _this.views.splice(index + 1);
              _this.resolves.splice(index);
              diffRuleIndex = index;
              break;
            }
            _this.nextRule = nextRule != null ? nextRule : _this.findRuleByUri($location.path());
          } else {
            if (_this.views.length) {
              _this.views.splice(1);
            }
            if (_this.resolves.length) {
              _this.resolves.splice(0);
            }
            _this.nextRule = nextRule != null ? nextRule : _this.findRuleByUri($location.path());
          }
        } else if (locationChanged) {
          _this.nextRule = nextRule != null ? nextRule : _this.findRuleByUri($location.path());
          diffRuleIndex = _this.nextRule.parents.length - 1;
          isBackToParent = _this.currentRule.namespace.indexOf(_this.nextRule.namespace + ".") === 0;
          ref1 = _this.nextRule.parents;
          for (index = j = 0, len1 = ref1.length; j < len1; index = ++j) {
            rule = ref1[index];
            oldRule = _this.currentRule.parents[index];
            isParamsDifferent = function() {

              /*
              Are the params different?
               */
              var paramKey, paramValue, ref2;
              ref2 = rule.getCurrentParams();
              for (paramKey in ref2) {
                paramValue = ref2[paramKey];
                if (_this.state.params[paramKey] !== paramValue) {
                  return true;
                }
              }
              return false;
            };
            if (!oldRule || oldRule.namespace !== rule.namespace) {
              diffRuleIndex = index;
              if (isParamsDifferent()) {
                isBackToParent = false;
              }
              break;
            }
            if (isParamsDifferent()) {
              isBackToParent = false;
              diffRuleIndex = index;
              break;
            }
          }
          if (diffRuleIndex < _this.views.length) {
            destroyViews = _this.views.splice(diffRuleIndex + (isBackToParent ? 1 : 0));
          }
          if (diffRuleIndex < _this.resolves.length) {
            _this.resolves.splice(diffRuleIndex + (isBackToParent ? 1 : 0));
          }
        } else if ((_this.nextRule == null) || _this.views.length > _this.nextRule.parents.length) {
          return;
        }
        stepStartChange = function(cancel) {

          /*
          Call this method when the render flow was started.
           */
          return $rootScope.$broadcast('$stateChangeStart', _this.generateStateObject(_this.nextRule), _this.state, cancel);
        };
        stepChanging = function() {

          /*
          Call this method when the resolve objects was done.
           */
          _this.updateOldState(_this.state);
          return _this.updateState(_this.generateStateObject(_this.nextRule));
        };
        stepCompletedChange = function() {

          /*
          Call this method when the finial render was done.
           */
          _this.currentRule = _this.nextRule;
          _this.nextRule = null;
          return $rootScope.$broadcast('$stateChangeSuccess', _this.state, _this.oldState);
        };
        stepChangeError = function(error) {
          return $rootScope.$broadcast('$stateChangeError', error);
        };
        if (((_this.currentRule == null) && _this.views.length === 1) || locationChanged) {
          tasks = [];
          fn = function(rule) {
            if (!isBackToParent || ruleIndex !== diffRuleIndex) {
              tasks.push(_this.fetchResolve(rule).then(function(result) {
                return _this.resolves[rule.parents.length - 1] = result;
              }));
            }
            if (rule.templateUrl) {
              return tasks.push(_this.fetchTemplate(rule.templateUrl).success(function(result) {
                return rule.template = result;
              }));
            }
          };
          for (ruleIndex = k = ref2 = diffRuleIndex, ref3 = _this.nextRule.parents.length; k < ref3; ruleIndex = k += 1) {
            rule = _this.nextRule.parents[ruleIndex];
            fn(rule);
          }
          cancel = false;
          stepStartChange(function() {
            return cancel = true;
          });
          if (cancel) {
            for (l = 0, len2 = destroyViews.length; l < len2; l++) {
              destroyView = destroyViews[l];
              _this.views.push(destroyView);
            }
            stepChanging();
            return;
          }
          return $q.all(tasks).then(function() {
            var isFinialView;
            stepChanging();
            if (destroyViews.length) {
              destroyViews[0].destroy();
              _this.views.push(destroyViews[0]);
            }
            isFinialView = (_this.nextRule.parents.length - 1) === diffRuleIndex;
            _this.views[diffRuleIndex].updateTemplate(_this.nextRule.parents[diffRuleIndex], _this.flattenResolve(_this.resolves.slice(0, diffRuleIndex + 1)), reload);
            if (isFinialView) {
              return stepCompletedChange();
            }
          }, function(error) {
            var len3, m;
            for (m = 0, len3 = destroyViews.length; m < len3; m++) {
              destroyView = destroyViews[m];
              _this.views.push(destroyView);
            }
            stepChanging();
            stepChangeError(error);
            return _this.renderViews(true, true, _this.findErrorHandlerRule());
          });
        } else {
          index = _this.views.length - 1;
          isFinialView = (_this.nextRule.parents.length - 1) === index;
          _this.views[index].updateTemplate(_this.nextRule.parents[index], _this.flattenResolve(_this.resolves.slice(0, index + 1)));
          if (isFinialView) {
            return stepCompletedChange();
          }
        }
      };
    })(this);
    this.findRuleByUri = (function(_this) {
      return function(uri) {

        /*
        Find the rule of the uri.
        @param uri {string}
         */
        var ref, rule, ruleName;
        ref = _this.rules;
        for (ruleName in ref) {
          rule = ref[ruleName];
          if (rule.matchReg.test(uri) && !rule.abstract) {
            return rule;
          }
        }
        return null;
      };
    })(this);
    this.findErrorHandlerRule = (function(_this) {
      return function() {

        /*
        Find the name of rule that is 'error'.
         */
        var ref, rule, ruleName;
        ref = _this.rules;
        for (ruleName in ref) {
          rule = ref[ruleName];
          if (ruleName === 'error') {
            return rule;
          }
        }
        return null;
      };
    })(this);
    this.flattenResolve = function(resolves) {

      /*
      Get the resolved object from resolves of all rules.
      @param resolves {list} @resolves
      @returns {object}
       */
      var i, key, len, resolve, result, value;
      result = {};
      for (i = 0, len = resolves.length; i < len; i++) {
        resolve = resolves[i];
        for (key in resolve) {
          value = resolve[key];
          result[key] = value;
        }
      }
      return result;
    };
    this.fetchResolve = (function(_this) {
      return function(rule) {

        /*
        Fetch resolve objects.
        @param rule {object} The rule object.
        @returns {$q}
         */
        var fn, func, key, params, ref, resolve, tasks;
        params = rule.getCurrentParams();
        tasks = [];
        resolve = {};
        ref = rule.resolve;
        fn = function(key, func) {
          return tasks.push($q.all([
            $injector.invoke(func, rule, {
              params: params
            })
          ]).then(function(result) {
            return resolve[key] = result[0];
          }));
        };
        for (key in ref) {
          func = ref[key];
          fn(key, func);
        }
        return $q.all(tasks).then(function() {
          return resolve;
        });
      };
    })(this);
    this.fetchTemplate = (function(_this) {
      return function(templateUrl) {

        /*
        Fetch template.
        @param templateUrl {string|function}
        @returns {$http}
         */
        return $http({
          method: 'get',
          url: typeof templateUrl === 'function' ? templateUrl() : templateUrl,
          cache: $templateCache,
          headers: {
            Accept: 'text/html'
          }
        });
      };
    })(this);
    this.generateStateObject = (function(_this) {
      return function(rule) {
        return {

          /*
          Generate state object.
          @param rule {object} The rule object.
          @returns {object}
              name: {string}
              params: {object}
           */
          name: rule.namespace,
          params: rule.getCurrentParams()
        };
      };
    })(this);
    this.updateOldState = (function(_this) {
      return function(state) {
        if (state == null) {
          state = {};
        }

        /*
        Update $router.oldState by the state object.
        @param state {object}
         */
        _this.oldState.name = state.name;
        return _this.oldState.params = state.params;
      };
    })(this);
    this.updateState = (function(_this) {
      return function(state) {

        /*
        Update $router.state by the state object.
        @param state {object}
         */
        _this.state.name = state.name;
        return _this.state.params = state.params;
      };
    })(this);
    this.register = (function(_this) {
      return function(namespace, args) {
        var hrefTemplate, i, j, len, len1, match, parentRule, ref, ref1, ref2, ruleUri, uriParamPattern, uriParamPatterns, uriQueryString;
        if (args == null) {
          args = {};
        }

        /*
        Register the router rule.
        @param namespace {string} The name of the rule.
        @param args {object} The router rule.
            abstract: {bool} This is abstract rule, it will render the child rule.
            uri: {string}  ex: '/projects/{projectId:[\w-]{20}}/tests/{testId:(?:[\w-]{20}|initial)}'
            resolve: {object}
            templateUrl: {string|function}
            controller: {string|list|function}
            onEnter: {function}
             * ---- generate by register
            namespace: {string}
            uriParams: {list}  ex: ['projectId', '?index']
            matchPattern: {string}  ex: '/projects/([\w-]{20})'
            matchReg: {RegExp} The regexp for .match()  ex: /^\/projects\/([\w-]{20})$/
            hrefTemplate: {string} The template for generating href.  ex: '/projects/{projectId}'
            getCurrentParams: {function}
            parents: {list}
         */
        args.namespace = namespace;
        if (args.uri == null) {
          args.uri = '';
        }
        if (!args.templateUrl) {
          args.template = '<div></div>';
        }
        if (namespace.indexOf('.') > 0) {
          parentRule = _this.rules[namespace.substr(0, namespace.lastIndexOf('.'))];
          args.uriParams = parentRule.uriParams.slice();
          args.matchPattern = parentRule.matchPattern;
          args.hrefTemplate = parentRule.hrefTemplate;
          args.parents = parentRule.parents.slice();
          args.parents.push(args);
        } else {
          args.uriParams = [];
          args.matchPattern = '';
          args.hrefTemplate = '';
          args.parents = [args];
        }
        uriParamPatterns = args.uri.match(/\{[\w]+:(?:(?!\/).)+/g);
        ruleUri = args.uri;
        hrefTemplate = args.uri;
        ref = uriParamPatterns != null ? uriParamPatterns : [];
        for (i = 0, len = ref.length; i < len; i++) {
          uriParamPattern = ref[i];
          match = uriParamPattern.match(/^\{([\w]+):((?:(?!\/).)*)\}$/);
          args.uriParams.push(match[1]);
          ruleUri = ruleUri.replace(uriParamPattern, "(" + match[2] + ")");
          hrefTemplate = hrefTemplate.replace(uriParamPattern, "{" + match[1] + "}");
        }
        ref2 = (ref1 = args.uri.match(/\?[\w-]+/g)) != null ? ref1 : [];
        for (j = 0, len1 = ref2.length; j < len1; j++) {
          uriQueryString = ref2[j];
          ruleUri = ruleUri.replace(uriQueryString, '');
          hrefTemplate = hrefTemplate.replace(uriQueryString, '');
          args.uriParams.push(uriQueryString);
        }
        args.matchPattern += ruleUri;
        args.matchReg = new RegExp("^" + args.matchPattern + "$");
        args.hrefTemplate += hrefTemplate;
        args.getCurrentParams = function() {

          /*
          Get params from uri and query string via $location.
          @returns {object}
           */
          var k, len2, param, ref3, result, uriParamsIndex;
          result = {};
          match = $location.path().match(new RegExp("^" + args.matchPattern));
          uriParamsIndex = 0;
          ref3 = args.uriParams;
          for (k = 0, len2 = ref3.length; k < len2; k++) {
            param = ref3[k];
            if (param.indexOf('?') === 0) {
              param = param.substr(1);
              result[param] = $location.search()[param];
            } else {
              result[param] = match[++uriParamsIndex];
            }
          }
          return result;
        };
        return _this.rules[namespace] = args;
      };
    })(this);
    this.registerView = (function(_this) {
      return function(view) {

        /*
        Register the view. `poi-view` should call this method when link.
        @param view {object}
            updateTemplate: {function}
            destroy: {function}
         */
        _this.views.push(view);
        return _this.renderViews();
      };
    })(this);
    this.go = (function(_this) {
      return function(namespace, params, options) {
        var search;
        if (options == null) {
          options = {};
        }

        /*
        Go to the url.
        @param namespace {string} The namespace of the rule or the url.
        @param params {object} The params of the rule.
        @param options {object}
            replace: {bool}
            reload: {bool}  If it is true, it will reload all views.
         */
        _this.isReloadAtThisRender = options.reload;
        if (namespace[0] === '/') {
          $location.url(namespace);
        } else {
          search = {};
          $location.path(_this.href(namespace, params, search));
          $location.search(search);
        }
        if (options.replace) {
          return $location.replace();
        }
      };
    })(this);
    this.reload = (function(_this) {
      return function(reloadParents) {

        /*
        Reload the current rule.
        This method will not reload parent views if reloadParents is null.
        @param reloadParents {bool|null}
         */
        return _this.renderViews(true, reloadParents != null ? reloadParents : _this.currentRule.namespace);
      };
    })(this);
    this.href = (function(_this) {
      return function(namespace, params, search) {
        var href, paramKey, paramValue, queryString, rule, usedKey;
        if (params == null) {
          params = {};
        }

        /*
        Generate the href by namespace and params.
        @param namespace {string} The namespace of the rule.
        @param params {object} The params of the rule.
        @param search {object|null} If it is an object, query string will appended at here, else append query string at href.
        @returns {string} The url.
         */
        rule = _this.rules[namespace];
        if (!rule) {
          throw new Error("Can't find the rule " + namespace + ".");
        }
        href = rule.hrefTemplate;
        usedKey = [];
        for (paramKey in params) {
          paramValue = params[paramKey];
          if (!(href.indexOf("{" + paramKey + "}") >= 0)) {
            continue;
          }
          href = href.replace("{" + paramKey + "}", encodeURIComponent(paramValue));
          usedKey.push(paramKey);
        }
        if (search != null) {
          for (paramKey in params) {
            paramValue = params[paramKey];
            if (indexOf.call(usedKey, paramKey) < 0) {
              search[paramKey] = paramValue;
            }
          }
        } else {
          queryString = [];
          for (paramKey in params) {
            paramValue = params[paramKey];
            if (indexOf.call(usedKey, paramKey) < 0) {
              queryString.push((encodeURIComponent(paramKey)) + "=" + (encodeURIComponent(paramValue)));
            }
          }
          if (queryString.length) {
            href += "?" + (queryString.join('&'));
          }
        }
        return href;
      };
    })(this);
    this.$get = [
      '$injector', (function(_this) {
        return function($injector) {
          _this.setupProvider($injector);
          return {
            oldState: _this.oldState,
            state: _this.state,
            register: _this.register,
            registerView: _this.registerView,
            go: _this.go,
            reload: _this.reload,
            href: _this.href
          };
        };
      })(this)
    ];
  });

}).call(this);

(function() {
  angular.module('poi.view', []).directive('poiView', [
    '$injector', function($injector) {
      var $compile, $controller, $router;
      $router = $injector.get('$router');
      $compile = $injector.get('$compile');
      $controller = $injector.get('$controller');
      return {
        restrict: 'A',
        link: function(scope, $element) {
          return $router.registerView({
            scope: null,
            rule: null,
            updateTemplate: function(rule, resolve, destroy) {

              /*
              Update the poi-view
              @param rule {Rule}
              @param resolve {object}
              @param destroy {bool} if it is true, call .$destroy()
               */
              var ref;
              if (destroy) {
                if ((ref = this.scope) != null) {
                  ref.$destroy();
                }
              } else if (this.rule) {
                if ($router.oldState.name.indexOf($router.state.name + ".") === 0) {
                  return;
                }
                this.scope.$destroy();
              }
              this.rule = rule;
              this.scope = scope.$new();
              if (rule.controller) {
                resolve.$scope = this.scope;
                if (rule.onEnter) {
                  $injector.invoke(rule.onEnter, rule, resolve);
                }
                $controller(rule.controller, resolve);
              }
              $element.html(rule.template);
              return $compile($element.contents())(this.scope);
            },
            destroy: function() {
              if (!this.rule) {
                return;
              }
              this.scope.$destroy();
              this.scope = null;
              this.rule = null;
              return $element.html('');
            }
          });
        }
      };
    }
  ]);

}).call(this);
