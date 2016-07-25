'use strict';

describe('Service: exportPDF', function () {

  // load the service's module
  beforeEach(module('asrApp'));

  // instantiate service
  var exportPDF;
  beforeEach(inject(function (_exportPDF_) {
    exportPDF = _exportPDF_;
  }));

  it('should do something', function () {
    expect(!!exportPDF).toBe(true);
  });

});
