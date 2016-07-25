'use strict';

angular.module('asrApp', [
   'ngCookies',
   'ngResource',
   'ngSanitize',
   'ui.router',
   'ui.bootstrap',
   'angular-momentjs',
   'angular-hal',
   'sprintf',
   'chart.js'
])
.config(function ($stateProvider, $urlRouterProvider, $locationProvider, $httpProvider, $momentProvider) {
   $urlRouterProvider.otherwise('/');
   $momentProvider.asyncLoading(false);
   $locationProvider.hashPrefix('!');
   $httpProvider.interceptors.push('authInterceptor');
})

.config(function (uibDatepickerConfig) {
   uibDatepickerConfig.showWeeks = false;
})

.factory('authInterceptor', function ($rootScope, $q, $cookieStore, $location) {
   return {
      // Add authorization token to headers
      // request: function (config) {
      //    config.headers = config.headers || {};
      //    if ($cookieStore.get('token')) {
      //       config.headers.Authorization = 'Bearer ' + $cookieStore.get('token');
      //    }
      //    return config;
      // },

      // Intercept 401s and redirect you to login
      responseError: function(response) {
         if(response.status === 401) {
            $location.path('/login');
            // remove any stale tokens
            $cookieStore.remove('mojolicious');
            return $q.reject(response);
         }
         else {
            return $q.reject(response);
         }
      }
   };
})

.run(function ($rootScope, $location, Auth) {
   // Redirect to login if route requires auth and you're not logged in
   $rootScope.$on('$stateChangeStart', function (event, next) {
      Auth.isLoggedInAsync(function(loggedIn) {
         if (next.authenticate && !loggedIn) {
            $location.path('/login');
         }
      });
   });
});
