UDP4PORT 	= process.env.GEOIP_UDP4PORT or 55317
PORT 		= process.env.GEOIP_PORT or 8123
TTL 		= process.env.GEOIP_TTL or 345600

dgram = require "dgram"
request = require "request"
nodecache = require "node-cache"
nc = new nodecache({stdTTL: TTL, checkperiod: 10000})

express = require "express"
morgan = require "morgan"

app = express()
app.use(morgan('combined'))
app.use (req, res, next) ->
    res.removeHeader("X-Powered-By")
    next()
    return

app.get '/ip/:ip', ( req, res ) ->
	_getip req.params.ip, (err, resp) ->
		if err
			res.status(400).send(err)
			return
		res.type("application/json").send(resp)
		return
	return

_getip = (ip, cb) ->
	ip = ip.toString().trim()
	if not _ipvalidate(ip)
		cb("invalid IP")
		return
	geoip = nc.get(ip)
	if geoip isnt undefined
		cb(null, geoip)
		return
	request "http://ip-api.com/json/#{ip}", (err, resp) ->
		if err
			cb(err)
			return
		nc.set(ip, resp.body)
		cb(null, resp.body)
		return
	return

_ipvalidate = (str) ->
	/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$|^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/.test(str)

server = dgram.createSocket("udp4")

server.on "message", (msg, rinfo) ->
	_getip msg, ->
		return
	return

server.on "listening", ->
	address = server.address()
	console.log "upd4 server listeing on #{address.address}:#{address.port}"
	return
server.bind(UDP4PORT)
app.listen(PORT)
console.log("Listening on port #{PORT}")