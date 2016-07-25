'use strict';

angular.module('asrApp')
  .controller('SettingsCtrl', function (User, Auth) {
    var settingsVM = this;
    settingsVM.errors = {};

    settingsVM.changePassword = function(form) {
      settingsVM.submitted = true;
      if(form.$valid) {
        Auth.changePassword( settingsVM.user.oldPassword, settingsVM.user.newPassword )
        .then( function() {
          settingsVM.message = 'Password successfully changed.';
        })
        .catch( function() {
          form.password.$setValidity('mongoose', false);
          settingsVM.errors.other = 'Incorrect password';
          settingsVM.message = '';
        });
      }
		};
  });
