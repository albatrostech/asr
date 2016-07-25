'use strict';

angular.module('asrApp')
.service('RestService', function ($q, halClient) {

   var restApiRoot = '/api';

   // Public API here
   return {
      fetch: function(rel, params) {
         return halClient.$get(restApiRoot).then(function(rootResource) {
            if (rootResource.$has(rel)) {
               return rootResource.$get(rel, params);
            } else {
               throw Error('Requested relation not found in the root resource.');
            }
         });
      },
      fetchPages: function (pagedHalResource, params) {
         var page = pagedHalResource.page;
         var totalPages = Math.ceil(page.totalItems/page.size);
         var promises = [];

         for (var i = 1; i <= totalPages; i++) {
            params.index = i;
            var promise = pagedHalResource.$get('self', params)
            .then(function(resource) {
               return resource;
            });

            promises.push(promise);
         }

         return $q.all(promises);
      },
      search: function(rel, params, searchRel) {
         return halClient.$get(restApiRoot).then(function(rootResource) {
            if (rootResource.$has(rel)) {
               return rootResource.$get(rel);
            } else {
               throw Error('Requested relation not found in API root resource.');
            }
         }).then(function(resource) {
            if (resource.$has('search')) {
               return resource.$get('search');
            } else {
               throw Error('Requested relation has no search resources.');
            }
         }).then(function(searchResource) {
            if (searchResource.$has(searchRel)) {
               return searchResource.$get(searchRel, params);
            } else {
               throw Error('Requested relation %s has no search %s');
            }
         });
      }
   };
});
