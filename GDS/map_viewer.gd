class_name MapViewer extends Control

const TILE_WIDTH:float = 256.0
const TILE_HEIGHT:float = 256.0

const MIN_ZOOM:float = 0.1
const MAX_ZOOM:float = 25.0

@export
var base_url:String = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png':
	set(v):
		if base_url != v:
			base_url = v
			_clean_all()
			queue_redraw()

@export_range(1,1000,1)
var max_concurrent_requests:int = 5

@export_range(100,100000,1)
var max_cached_tiles:int = 200

@export_range(0,25,1)
var max_zoom_level:int = 21

var _xyz:Vector3 = Vector3(0,0,2.5)
var _cache:Dictionary = {}
var _queue:Dictionary = {}
var _error:Dictionary = {}
var _dragging:bool = false
var _drag_pos:Vector2 = Vector2.ZERO
var _last_error_check:int = 0
var _last_cache_check:int = 0
var _rollover:bool = false
var _cursor:Vector2 = Vector2.ZERO

func _ready():
	
	# on mouse enter
	connect('mouse_entered', func():
		_rollover = true
		queue_redraw()
	)
	
	# on mouse exit
	connect('mouse_exited', func():
		_rollover = false
		queue_redraw()
	)

func _input(e):
	if Engine.is_editor_hint():
		return
	
	if e is InputEventMouseButton:
		if e.pressed and _rollover:
			if e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				apply_zoom(0.95, get_local_mouse_position())
			elif e.button_index == MOUSE_BUTTON_WHEEL_UP:
				apply_zoom(1.05, get_local_mouse_position())
		
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed and _rollover:
				_dragging = true
				var lmp = get_local_mouse_position()
				_drag_pos = screen_to_world(lmp.x, lmp.y)
			else:
				_dragging = false
	
	elif e is InputEventMouseMotion:
		_cursor = get_local_mouse_position()
		
		if _dragging:
			var lmp = get_local_mouse_position()
			var wp = screen_to_world(lmp.x, lmp.y)
			var diff = _drag_pos - wp
			_xyz.x += diff.x
			_xyz.y += diff.y
		
		queue_redraw()

func apply_zoom(multiplier: float, pivot: Vector2):
	var p1 = screen_to_world(pivot.x, pivot.y)
	_xyz.z = max(min(_xyz.z*multiplier, MAX_ZOOM),MIN_ZOOM)
	var p2 = screen_to_world(pivot.x, pivot.y)
	_xyz.x -= p2.x-p1.x
	_xyz.y -= p2.y-p1.y
	queue_redraw()

func _draw():
	
	# clear background
	draw_rect(Rect2(Vector2.ZERO,size), Color('#ffffff'), true)
	
	# draw zoomlevel 0
	_draw_tile(0,0,0)
	
	# draw zoomlevel 1
	_draw_tile(0,0,1)
	_draw_tile(1,0,1)
	_draw_tile(0,1,1)
	_draw_tile(1,1,1)
	
	# draw all other zoomlevels
	if _xyz.z >= 1:
		var z = min(max_zoom_level, _xyz.z)
		var t1 = screen_to_tile(0, 0, z, true)
		var t2 = screen_to_tile(size.x, size.y, z, true)
		for tx in range(t1.x,t2.x+1):
			for ty in range(t1.y,t2.y+1):
				_draw_tile(tx,ty,z)
	
	# draw cursor
	var font = Label.new().get_theme_font('')
	var ll = screen_to_lonlat(_cursor.x,_cursor.y)
	var text = lonlat_to_dms(ll.x, ll.y)
	draw_string(font, _cursor+Vector2(10,12), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.RED)

func _clean_all():
	_queue.clear()
	_cache.clear()
	_error.clear()
	for c in get_children():
		remove_child(c)

# get the tile from queue with the newest timestamp
func get_next_in_queue():
	if _queue.is_empty():
		return null
	var tile = null
	for idx in _queue:
		var t = _queue.get(idx)
		if not tile or t.t > tile.t:
			tile = t
	return tile

# delete oldest tiles from cache
func _clean_cache():
	var overflow = _cache.size() - max_cached_tiles
	if overflow <= 0:
		return
	
	var list = _cache.values()
	list.sort_custom(func(t1,t2):
		return t1.t < t2.t
	)
	for i in range(overflow):
		var t = list[i]
		_cache.erase(t.i)

func _clean_errors():
	var now = Time.get_unix_time_from_system()
	var keys = _error.keys()
	for idx in keys:
		var t = _error.get(idx)
		var d = now - t.t
		if d > 10:
			_error.erase(t.i)

func _process(delta):
	
	var now = Time.get_unix_time_from_system()
	
	# reset tile errors
	if not _last_error_check or now - _last_error_check > 10:
		_last_error_check = now
		_clean_errors()
	
	# if cache is overflowing - clean it
	if not _last_cache_check or now - _last_cache_check > 5:
		_last_cache_check = now
		_clean_cache()
	
	# if queue contains items - and new requests can be made
	while not _queue.is_empty() and get_child_count() < max_concurrent_requests:
		var tile = get_next_in_queue()
		if not tile:
			return
		
		var req = HTTPRequest.new()
		req.set_meta('tile', tile)
		add_child(req)
		req.name = str(tile.i)
		req.request_completed.connect(_response.bind(req,tile))
		req.use_threads = true
		_queue.erase(tile.i)
		if req.request(tile.url) != OK:
			tile.t = Time.get_unix_time_from_system()
			_error[tile.i] = tile
			remove_child(req)

# result, response_code, headers, body
func _response(result,code,headers,body,req,tile):
	
	remove_child(req)
	
	if code == 404:
		prints('File not found')
		tile.t = Time.get_unix_time_from_system()
		_error[tile.i] = tile
		return
	
	# get the image type from the reponse header
	var h = ''.join(headers)
	var type = ''
	if   h.contains('image/png'):  type = 'png'
	elif h.contains('image/jpg'):  type = 'jpg'
	elif h.contains('image/jpeg'): type = 'jpg'
	elif h.contains('image/bmp'):  type = 'bmp'
	elif h.contains('image/tga'):  type = 'tga'
	elif h.contains('image/webp'): type = 'webp'
	
	# unrecognized image type
	if not type:
		prints('Unrecognized image type')
		tile.t = Time.get_unix_time_from_system()
		_error[tile.i] = tile
		return
	
	# construct image from response body
	var image = Image.new()
	var error = OK
	if   type == 'png':		error = image.load_png_from_buffer(body)
	elif type == 'jpg':		error = image.load_jpg_from_buffer(body)
	elif type == 'bmp':		error = image.load_bmp_from_buffer(body)
	elif type == 'tga':		error = image.load_tga_from_buffer(body)
	elif type == 'webp':	error = image.load_webp_from_buffer(body)
	if error != OK:
		prints('Could not load the '+type+' image')
		tile.t = Time.get_unix_time_from_system()
		_error[tile.i] = tile
		return
	
	# create texture from image and add it to the cache
	var texture = ImageTexture.create_from_image(image)
	tile.texture = texture
	_cache[tile.i] = tile
	
	# redraw the map
	queue_redraw()

func _draw_subtile(tx:int, ty:int, tz:int, origx:int, origy:int, origz:float) -> bool:
	var subtile = get_tile(tx, ty, tz)
	if not subtile:
		return false
	
	var p1 = tile_to_screen(origx,origy, origz)
	var p2 = tile_to_screen(origx+1, origy+1, origz)
	var x1 = tile_to_screen(tx,ty, tz)
	var x2 = tile_to_screen(tx+1, ty+1, tz)
	
	var xdiff = x2.x - x1.x
	var xrat1 = (p1.x - x1.x) / xdiff
	var xrat2 = (p2.x - x1.x) / xdiff
	var xwidth = xrat2-xrat1
	
	var ydiff = x2.y - x1.y
	var yrat1 = (p1.y - x1.y) / ydiff
	var yrat2 = (p2.y - x1.y) / ydiff
	var yheight = yrat2-yrat1
	
	var rect = Rect2(xrat1*TILE_WIDTH, yrat1*TILE_HEIGHT,xwidth*TILE_WIDTH, yheight*TILE_HEIGHT)
	if subtile.texture:
		draw_texture_rect_region(subtile.texture, Rect2(p1, p2-p1), rect)
		return true
	return false

func _draw_tile(tx:int, ty:int, z:float):
	
	var tz = floor(z)
	var p1 = tile_to_screen(tx,ty, z)
	var p2 = tile_to_screen(tx+1, ty+1, z)
	var p3 = p1 + (p2-p1) / 2
	
	var tile = get_tile(tx,ty,tz)
	if tile:
		if tile.texture:
			draw_texture_rect(tile.texture, Rect2(p1, p2-p1), false, Color.WHITE, false)
		else:
			var zzz = tz
			var txx = tx
			var tyy = ty
			while zzz > 1:
				zzz -= 1
				txx = floor(txx/2)
				tyy = floor(tyy/2)
				if _draw_subtile(txx, tyy, zzz, tx,ty,z):
					break

## convert lon/lat to world coords
func lonlat_to_world(lon:float, lat:float) -> Vector2:
	var x = lon / 180.0
	var latsin = sin(deg_to_rad(lat) * sign(lat))
	var y = (sign(lat) * (log((1.0+latsin) / (1.0-latsin)) / 2.0)) / PI
	return Vector2(x,y)

## convert lon/lat to screen coords
func lonlat_to_screen(lon:float, lat:float) -> Vector2:
	var w = lonlat_to_world(lon,lat)
	return world_to_screen(w.x,w.y)

## convert lon/lat to tile coords
func lonlat_to_tile(lon:float, lat:float, z:float, do_floor:bool=false) -> Vector2:
	var w = lonlat_to_world(lon,lat)
	return world_to_tile(w.x, w.y, z, do_floor)

## convert world coords to lon/lat
func world_to_lonlat(wx:float, wy:float) -> Vector2:
	var lon = wx * 180.0
	var lat = rad_to_deg(atan(sinh(wy * PI)))
	return Vector2(lon,lat)

## convert screen coords to lon/lat
func screen_to_lonlat(sx:float, sy:float) -> Vector2:
	var w = screen_to_world(sx,sy)
	return world_to_lonlat(w.x, w.y)

## convert tile coords to lon/lat
func tile_to_lonlat(tx:float, ty:float, tz:float) -> Vector2:
	var w = tile_to_world(tx, ty, tz)
	return world_to_lonlat(w.x, w.y)

## convert screen coords to world coords
func screen_to_world(sx:float, sy:float) -> Vector2:
	var n = pow(2.0, _xyz.z)
	var span_w = n * TILE_WIDTH
	var span_h = n * TILE_HEIGHT
	var px = sx - size.x/2 + span_w/2
	var py = sy - size.y/2 + span_h/2
	var xr = px / span_w
	var yr = py / span_h
	var x = (xr*2.0-1.0) + _xyz.x
	var y = ((-yr*2.0)+1.0) + _xyz.y
	return Vector2(x,y)

## convert screen coords to tile coords
func screen_to_tile(sx:float, sy:float, z:float, do_floor:bool=false) -> Vector2:
	var world = screen_to_world(sx,sy)
	return world_to_tile(world.x, world.y, z, do_floor)

## convert tile coords to screen coords
func tile_to_screen(tx:float, ty:float, tz:float) -> Vector2:
	var w = tile_to_world(tx, ty, tz)
	return world_to_screen(w.x, w.y)

## convert tile coords to world coords
func tile_to_world(tx:float, ty:float, tz:float) -> Vector2:
	var n = pow(2.0, floor(tz))
	var x = (tx / n) * 2.0 - 1.0
	var y = -((ty / n) * 2.0 - 1.0)
	return Vector2(x,y)

## convert world coords to tile coords
func world_to_tile(wx:float, wy:float, z:float, do_floor:bool=false) -> Vector2:
	var n = pow(2.0, floor(z))
	var tx = ((wx+1.0) / 2.0) * n
	var ty = ((-wy + 1.0) / 2.0) * n
	if do_floor:
		tx = floor(tx)
		ty = floor(ty)
	return Vector2(tx,ty)

## convert world coords to screen coords
func world_to_screen(wx:float, wy:float) -> Vector2:
	var n = pow(2.0, _xyz.z)
	var w = n * TILE_WIDTH
	var h = n * TILE_HEIGHT
	var xr = (((wx-_xyz.x)+1.0)/2.0)
	var yr = ((-(wy-_xyz.y)+1.0)/2.0)
	var x = w * xr - w/2 + size.x/2
	var y = h * yr - h/2 + size.y/2
	return Vector2(x,y)

## get the tile index from xyz tile coords
func xyz_to_idx(x:int, y:int, z:int)->int:
	var i = (pow(4,z)-1) / 3
	var n = pow(2,z)
	return i + (y * n + x)

func get_tile(x:int, y:int, z:int, create:bool=true)->Tile:
	
	# out of bounds
	var n = pow(2, z)
	if z < 0 or x < 0 or x >= n or y < 0 or y >= n:
		return null
	
	# get tile index
	var idx = xyz_to_idx(x,y,z)
	var now = Time.get_unix_time_from_system()
	var tile = null
	
	# retrieve from error queue
	tile = _error.get(idx)
	if tile:
		return tile
	
	# retrieve from current requests...
	var req = find_child(str(idx), false, false)
	if req:
		tile = req.get_meta('tile')
		tile.t = now
		return tile
	
	# retrieve from cache
	tile = _cache.get(idx)
	if tile:
		tile.t = now
		return tile
	
	# retrieve from queue
	tile = _queue.get(idx)
	if tile:
		tile.t = now
		return tile
	
	# create a new tile - add it to queue
	if create:
		tile = Tile.new(idx,x,y,z)
		tile.url = base_url.replace('{x}',str(x)).replace('{y}', str(y)).replace('{z}', str(z))
		tile.t = now
		_queue[idx] = tile
	return tile

func lonlat_to_dms(lon:float, lat:float) -> String:
	var pf = 'N' if lat >= 0 else 'S'
	lat = abs(lat)
	var deg = floor(lat)
	var minute = (lat - deg) * 60
	var second = (minute - floor(minute)) * 60
	var text = ('%02d'%deg)+('%02d'%floor(minute))+('%02d'%floor(second))+(pf)+(' ')

	pf = 'E' if lon >= 0 else 'W'
	lon = abs(lon)
	deg = floor(lon)
	minute = (lon - deg) * 60
	second = (minute - floor(minute)) * 60
	text += ('%02d'%deg)+('%02d'%floor(minute))+('%02d'%floor(second))+(pf)
	
	return text

class Tile:
	var i:int = 0
	var x:int = 0
	var y:int = 0
	var z:int = 0
	var t:int = 0
	var url:String = ''
	var texture:Texture2D = null
	
	func _init(i:int, x:int, y:int, z:int):
		self.i = i
		self.x = x
		self.y = y
		self.z = z
