'use strict';

angular.module('asrApp')
.factory('User', function ($resource) {
   return $resource('/auth/:controller', {}, {
      changePassword: {
         method: 'POST',
         params: {
            controller: 'passwd'
         }
      },
      get: {
         method: 'GET',
         params: {
            controller: 'me'
         }
      }
   });
});
