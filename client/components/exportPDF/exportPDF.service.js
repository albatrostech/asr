'use strict';

angular.module('asrApp')
.factory('ExportPDF', function (Format) {
   // fillColors holds the seven colors used by angular-chart.js
   // jsPDF uses RGB format for colors
   var fillColors = [
      [151, 187, 205], // blue
      [220, 220, 220], // light grey
      [247, 70, 74],   // red
      [70, 191, 189],  // green
      [253, 180, 92],  // yellow
      [148, 159, 177], // grey
      [77, 83, 96]     // dark grey
   ];

   // Public API
   return {
      createPDF: function (names, columnsName, data, labelsBytes, labelsTime, bytesImg, timeImg) {
         var pdf = new jsPDF('p', 'pt', 'letter');
         var columnData = [];

         // Sets rectangles and text position, and make rounded rectangles with color
         var setGraphLabels = function(labels, x) {
            for (var i = 0; i < labels.length; i++) {
               var color = fillColors[i];
               pdf.setFillColor(color[0], color[1], color[2]);
               pdf.roundedRect(x, 190 + i * 25, 15, 15, 3, 3, 'FD');
               pdf.text(x + 20, 201 + i * 25, labels[i]);
            }
         };

         // Both graph titles
         pdf.setFontSize(12);
         pdf.text(100, 120, names.chartBytesTitle);
         pdf.text(370, 120, names.chartTimeTitle);

         // Font size and square border color for graph info
         pdf.setFontSize(8);
         pdf.setDrawColor(255, 255, 255);

         // Top bytes graph
         pdf.addImage(bytesImg, 'PNG', -50, 140);
         setGraphLabels(labelsBytes, 195);

         // Top time graph
         pdf.addImage(timeImg, 'PNG', 220, 140);
         setGraphLabels(labelsTime, 465);

         // Row data for table, since hal+json can be an array of objects or just one object
         // Inside the forEach must be checked if the hal is an array or not to do the right push
         data.forEach(function(data) {
            if (Array.isArray(data)) {
               data.forEach(function(rowData) {
                  columnData.push([
                     rowData[names.relation],
                     Format.formatBytes(rowData.bytes),
                     Format.formatPercent(rowData.bytes_percent),
                     Format.formatDurationInSeconds(rowData.seconds),
                     Format.formatPercent(rowData.seconds_percent)
                     ]);
                  });
               } else {
                  columnData.push([
                     data[names.relation],
                     Format.formatBytes(data.bytes),
                     Format.formatPercent(data.bytes_percent),
                     Format.formatDurationInSeconds(data.seconds),
                     Format.formatPercent(data.seconds_percent)
                     ]);
                  }
               });

         // header, footer and options uses jsPDF-AutoTable especifications
         // jsPDF plugin https://github.com/someatoms/jsPDF-AutoTable
         var header = function (doc, pageCount, options) {
            doc.setFontSize(14);
            doc.text(names.header, options.margins.horizontal, 60);
            doc.setFontSize(options.fontSize);
         };

         var footer = function (doc, lastCellPos, pageCount, options) {
            var pageNumber = 'Page ' + pageCount;
            doc.text('ASR application', options.margins.horizontal, doc.internal.pageSize.height - 30);
            doc.text(pageNumber, doc.internal.pageSize.width - 75, doc.internal.pageSize.height - 30);
         };

         var options = {renderHeader: header, renderFooter: footer, margins: {horizontal: 40, top: 80, bottom: 50}, startY: 360};

         // Create table and save pdf file
         pdf.autoTable(columnsName, columnData, options);
         pdf.save([names.pdfName, 'pdf'].join('.'));
      }
   };
});
