'use strict';

angular.module('asrApp')
.config(function ($stateProvider) {
   $stateProvider
   .state('sites', {
      url: '/sites?size&index&start&end&sort&user',
      templateUrl: 'app/sites/sites.html',
      controller: 'SitesCtrl as list',
      params: {
         size: '10',
         index: '1',
         sort: 'total_bytes.desc'
      },
      resolve: {
         sitesResource: function($stateParams, RestService) {
            if ($stateParams.user) {
               return RestService.search('sites', {
                  index: $stateParams.index,
                  size: $stateParams.size,
                  user: $stateParams.user,
                  sort: $stateParams.sort,
                  start: $stateParams.start,
                  end: $stateParams.end
               },
               'findByUser');
            } else {
               return RestService.fetch('sites', {
                  index: $stateParams.index,
                  size: $stateParams.size,
                  sort: $stateParams.sort,
                  start: $stateParams.start,
                  end: $stateParams.end
               });
            }
         },
         chartResourceBytes: function($stateParams, RestService) {
            if ($stateParams.user) {
               return RestService.search('sites', {
                  user: $stateParams.user,
                  size: 3,
                  sort: 'total_bytes.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               },
               'findByUser');
            } else {
               return RestService.fetch('sites', {
                  size: 3,
                  sort: 'total_bytes.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               });
            }
         },
         chartResourceTime: function($stateParams, RestService) {
            if ($stateParams.user) {
               return RestService.search('sites', {
                  user: $stateParams.user,
                  size: 3,
                  sort: 'total_time.desc',
                  start: $stateParams.start,
                  end: $stateParams.end
               },
               'findByUser');
            } else {
               return RestService.fetch('sites', {
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
