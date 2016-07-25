'use strict';

angular.module('asrApp')
.config(function ($stateProvider) {
   $stateProvider
   .state('users', {
      url: '/users?size&index&start&end&sort&site',
      templateUrl: 'app/users/users.html',
      controller: 'UsersCtrl as list',
      params: {
         size: '10',
         index: '1',
         sort: 'total_bytes.desc'
      },
      resolve: {
         usersResource: function($stateParams, RestService) {
            if ($stateParams.site) {
               return RestService.search('users', {
                  index: $stateParams.index,
                  size: $stateParams.size,
                  site: $stateParams.site,
                  sort: $stateParams.sort,
                  start: $stateParams.start,
                  end: $stateParams.end
               },
               'findBySite');
            } else {
               return RestService.fetch('users', {
                  index: $stateParams.index,
                  size: $stateParams.size,
                  sort: $stateParams.sort,
                  start: $stateParams.start,
                  end: $stateParams.end
               });
            }
         },
         chartResourceBytes: function($stateParams, RestService) {
            if ($stateParams.site) {
               return RestService.search('users', {
                  site: $stateParams.site,
                  size: 3,
                  sort: 'total_bytes.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               },
               'findBySite');
            } else {
               return RestService.fetch('users', {
                  size: 3,
                  sort: 'total_bytes.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               });
            }
         },
         chartResourceTime: function($stateParams, RestService) {
            if ($stateParams.site) {
               return RestService.search('users', {
                  site: $stateParams.site,
                  size: 3,
                  sort: 'total_time.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               },
               'findBySite');
            } else {
               return RestService.fetch('users', {
                  size: 3,
                  sort: 'total_time.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               });
            }
         }
      }
   });
});
