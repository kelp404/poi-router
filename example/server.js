(function() {
  var app, express, http, path, server;

  http = require('http');

  path = require('path');

  express = require('express');

  app = express();

  server = http.createServer(app);

  app.use('/poi-router', express["static"](path.join(__dirname, '..')));

  server.listen('8000', '0.0.0.0', function() {
    var address;
    address = server.address();
    return console.log('Server listening at http://%s:%s', address.address, address.port);
  });

}).call(this);
