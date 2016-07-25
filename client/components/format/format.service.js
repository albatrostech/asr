'use strict';

angular.module('asrApp')
.factory('Format', function ($moment) {
   var k = 1024;
   var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

   // Public API here
   return {
      formatBytes: function (bytes) {
         if(bytes === 0) { return '0 Byte'; }
         var i = Math.floor(Math.log(bytes) / Math.log(k));
         return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
      },
      formatPercent: function (value, digits) {
         return value.toFixed(digits || 2) + '%';
      },
      formatDurationInSeconds: function (milis) {
         return $moment.duration(milis / 1000, 'seconds').humanize();
      },
      floor: function (value) {
         return Math.floor(value);
      },
      none: function(data) {
         return data;
      }
   };
});
