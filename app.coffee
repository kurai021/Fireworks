###
Module dependencies.
###
express = require("express")
jade = require("jade")
stylus = require("stylus")
nib = require("nib")
twitter = require("ntwitter")
routes = require("./routes")
user = require("./routes/user")
app = express()
path = require("path")
server = require("http").createServer(app)
io = require("socket.io").listen(server)

num_tweets = 0
twit = new twitter(
  consumer_key: 'PCcNcIphzz2wyt5FAOpTAg'
  consumer_secret: 'C6rVqxRcpORSfZdq088OylGbyz8Xz4PwBMYuW9M0dl0'
  access_token_key: '305235468-SN4VrhtSYKQ5XBVwi8WRXFhMt6JE4fp1rrYfMVjw'
  access_token_secret: 'pdUEbGSBIG6VdSo8mKO0Djt8E7DxM4evKJQsGJKDWDJEM'
)

io.sockets.on "connection", (socket) ->
  twit.stream "statuses/filter",
    track: "christmas"
  , (stream) ->
    stream.on "data", (data) ->
      num_tweets++
      if num_tweets % 10 is 0
        socket.emit "tweet",
          data: data.text

        console.log data.text
        console.log num_tweets
        console.log "------------------------------"

    stream.on "error", (data) ->
      console.log data


  socket.on "disconnect", ->
    console.log "Client Disconnected"    

compile = (str, path) ->
  stylus(str).set("filename", path).use nib() 

# all environments
app.set "port", process.env.PORT or 8000
app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use stylus.middleware(src: __dirname + '/public', compile: compile)
app.use express.static(path.join(__dirname, "public"))

# production only
app.use express.errorHandler()  if "production" is app.get("env")
app.get "/", routes.index
app.get "/users", user.list
server.listen app.get("port"), ->
  # if run as root, downgrade to the owner of this file
  if process.getuid() is 0
    require("fs").stat __filename, (err, stats) ->
      return console.error(err) if err
      process.setuid stats.uid
  
  console.log "Express server listening on port " + app.get("port")
