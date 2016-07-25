'use strict';

angular.module('asrApp')
.controller('SitesCtrl', function ($state, $stateParams, $q, sitesResource, Format, chartResourceBytes, chartResourceTime, RestService, ExportPDF) {

   var self = this;
   var caretDir = function() {
      Object.keys(self.columns).forEach(function(columnName) {
         var splitSort = self.sort.split('.');
         if (splitSort[0] === self.columns[columnName].remoteColumn) {
            self.columns[columnName].sortDir = splitSort[1];
         }
      });
   };

   self.startDate = $stateParams.start;
   self.endDate = $stateParams.end;
   self.sort = $stateParams.sort;
   self.index = $stateParams.index;
   self.size = $stateParams.size;
   self.viewTitle = $stateParams.user ? ['Sites of User', $stateParams.user].join(' ') : 'Sites';
   self.chartBytesTitle = 'Top 3 Sites by Bytes';
   self.chartTimeTitle = 'Top 3 Sites by Time';

   if (sitesResource.$has('sites')) {
      sitesResource.$get('sites').then(function(sites) {
         self.sites = [];

         // users (hal+json) can be an array of objects or just one object
         // must be checked if users is an array or not
         if (Array.isArray(sites)) {
            self.sites = sites;
         } else {
            // If an object push it to the empty array
            self.sites.push(sites);
         }

         // This let bootstrap pagination calculate the nunmber of pages
         self.totalItems = sitesResource.page.totalItems;

         if (self.sort) {
            // Set column sort direction from sort param
            caretDir();
         }
      });
   }

   if (chartResourceBytes.$has('sites')) {
      chartResourceBytes.$get('sites').then(function(chartBytes) {
         self.chartBytes = [];

         // chartBytes (hal+json) can be an array of objects or just one object
         // must be checked if chartBytes is an array or not
         if (Array.isArray(chartBytes)) {
            self.chartBytes = chartBytes;
         } else {
            // If an object push it to the empty array
            self.chartBytes.push(chartBytes);
         }

         // Generates the data for bytes chart
         chartTopBytes();
      });
   }

   if (chartResourceTime.$has('sites')) {
      chartResourceTime.$get('sites').then(function(chartTime) {
         self.chartTime = [];

         // chartTime (hal+json) can be an array of objects or just one object
         // must be checked if chartTime is an array or not
         if (Array.isArray(chartTime)) {
            self.chartTime = chartTime;
         } else {
            // If an object push it to the empty array
            self.chartTime.push(chartTime);
         }

         // Generates the data for time chart
         chartTopTime();
      });
   }

   self.columns = {
      'site': {
         label: 'Site',
         format: Format.none,
         order: 0,
         remoteColumn: 'site',
         sortDir: null
      },
      'bytes': {
         label: 'Bytes',
         format: Format.formatBytes,
         order: 1,
         remoteColumn: 'total_bytes',
         sortDir: null
      },
      'bytes_percent': {
         label: 'Bytes %',
         format: Format.formatPercent,
         order: 2,
         remoteColumn: 'bytes_percent',
         sortDir: null
      },
      'seconds': {
         label: 'Time',
         format: Format.formatDurationInSeconds,
         order: 3,
         remoteColumn: 'total_time',
         sortDir: null
      },
      'seconds_percent': {
         label: 'Time %',
         format: Format.formatPercent,
         order: 4,
         remoteColumn: 'time_percent',
         sortDir: null
      }
   };

   self.columnNames = Object.keys(self.columns).sort(function (a, b) {
      return self.columns[a].order - self.columns[b].order;
   });

   self.sortColumn = function($event, column) {
      var params = {};
      var sortDir;

      switch (self.columns[column].sortDir) {
         case 'asc':
            sortDir = null;
            break;
         case 'desc':
            sortDir = 'asc';
            break;
         default:
            sortDir = 'desc';
      }

      if (sortDir) {
         params.sort = [self.columns[column].remoteColumn, sortDir].join('.');
      } else {
         params.sort = sortDir;
      }

      $state.go('sites', params);
   };

   self.newIndex = function() {
      $state.go('sites', {index: self.index});
   };

   var chartTopBytes = function() {
      self.labelsBytes = [];
      self.dataBytes = [];
      self.chartBytes.forEach(function(bytes) {
         self.labelsBytes.push(bytes.site);
         self.dataBytes.push(bytes.bytes);
      });

      self.bytesChartOptions = {
         tooltipTemplate : function (data) {
            return data.label + ': ' + Format.formatBytes(data.value);
         }
      };
   };

   var chartTopTime = function() {
      self.labelsTime = [];
      self.dataTime = [];
      self.chartTime.forEach(function(time) {
         self.labelsTime.push(time.site);
         self.dataTime.push(time.seconds);
      });

      self.timeChartOptions = {
         tooltipTemplate : function (data) {
            return data.label + ': ' + Format.formatDurationInSeconds(data.value);
         }
      };
   };

   // PDF
   self.makePDF = function() {
      RestService.fetchPages(sitesResource, $stateParams)
      .then(function(resources) {
         var promises = [];

         resources.forEach(function(resource) {
            var promise = resource.$get('sites')
            .then(function(sites) {
               return sites;
            });

            promises.push(promise);
         });

         return $q.all(promises);
      })
      .then(function(data) {
         // Object that holds names for exportPDF
         var columnsName = [];
         var names = {};
         var siteName = $stateParams.user ? ['sites_of_user', $stateParams.user].join('_') : 'sites';
         names.pdfName = [siteName, self.startDate, self.endDate].join('_');
         names.chartBytesTitle = self.chartBytesTitle;
         names.chartTimeTitle = self.chartTimeTitle;
         names.relation = 'site';
         names.header = ['Report for', self.viewTitle, 'from', self.startDate, 'to', self.endDate].join(' ');

         // Columns name for table
         Object.keys(self.columns).forEach(function(columnName) {
            columnsName.push(self.columns[columnName].label);
         });

         // Turn the graph into an image
         var bytesImg  = document.getElementById('chartBytes').toDataURL();
         var timeImg  = document.getElementById('chartTime').toDataURL();

         // Send data to exportPDF
         ExportPDF.createPDF(names, columnsName, data, self.labelsBytes, self.labelsTime, bytesImg, timeImg);
      });
   }; // makePDF end
});
