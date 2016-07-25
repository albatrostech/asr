'use strict';

angular.module('asrApp')
.controller('NavbarCtrl', function ($scope, $location, Auth, $state, $stateParams, $moment) {
   $scope.menu = [{
      'title': 'Users',
      'link': 'users'
   },{
      'title': 'Sites',
      'link': 'sites'
   }];

   $scope.isCollapsed = true;
   $scope.isLoggedIn = Auth.isLoggedIn;
   $scope.isAdmin = Auth.isAdmin;
   $scope.getCurrentUser = Auth.getCurrentUser;

   $scope.logout = function() {
      Auth.logout();
      $location.path('/login');
   };

   $scope.isActive = function(route) {
      return route === $location.path();
   };

   $scope.showPickers = function() {
      return $state.includes('users') || $state.includes('sites');
   };

   // Datepicker
   $scope.endDate = $stateParams.end ? $moment($stateParams.end).toDate() :
      $moment().toDate();
   $scope.startDate = $stateParams.start ? $moment($stateParams.start).toDate() :
      $moment().subtract(15, 'days').toDate();

   $scope.maxDate = new Date();

   $scope.$watch('startDate', function () {
      $scope.applyDate();
   });
   $scope.$watch('endDate', function () {
      $scope.applyDate();
   });

   $scope.tooglePicker = function(picker) {
      $scope[picker] = !$scope[picker];
   };

   $scope.getDateParams = function() {
      var params = {};

      params.start = $scope.startDate.toISOString().split('T')[0];
      params.end = $scope.endDate.toISOString().split('T')[0];

      return params;
   };

   $scope.applyDate = function() {
      $state.go($state.current, $scope.getDateParams());
   };
});
