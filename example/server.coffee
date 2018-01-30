http = require 'http'
path = require 'path'
express = require 'express'


app = express()
server = http.createServer app

app.use '/poi-router', express.static(path.join(__dirname, '..'))

server.listen '8000', '0.0.0.0', ->
    address = server.address()
    console.log 'Server listening at http://%s:%s', address.address, address.port
