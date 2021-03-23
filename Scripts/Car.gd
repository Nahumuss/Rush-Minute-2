extends Node2D
class_name Car

var length = 0
var direction : bool = false # Vertical if true
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var path
var chosen_texture = null
var tiles = []
var color = ''

func _ready():
	pass

# Called on the car's initialization
func init(tiles_pos : Array, direction : bool, color : String) -> void:
	rng.randomize()
	if direction:
		tiles_pos.invert()
	for tile_pos in tiles_pos:
		add_tile(tile_pos)
	self.direction = direction
	self.length = len(tiles_pos)
	self.color = color
	path = "res://Sprites/Cars/" + str(length) + "x1/"
	var textures : Array = get_list_in_dir(path)
	if len(textures) > 0:
		var spb : StreamPeerBuffer = StreamPeerBuffer.new()
		spb.data_array = color.to_ascii()
		var chosen_num = spb.get_16() % len(textures)
		chosen_texture = textures[chosen_num]
	fix_rotation()
	draw_car()

func add_tile(tile_pos):
	var tile : Tile = load("res://Prefabs/Tile.tscn").instance()
	tile.set_tile_board_pos(Vector2(tile_pos))
	self.add_child(tile)

# Fixes the rotation of the car by the direction variable
func fix_rotation() -> void:
	for tile in get_children():
		var last_rotation = tile.get_rotation_degrees()
		if direction and last_rotation != 90:
			tile.set_rotation(deg2rad(90))
		elif direction and last_rotation != 0:
			tile.set_rotation(deg2rad(90))

# Resets the position of the car's tiles
func reset() -> void:
	for tile in get_children():
		tile.reset()

# Sets the car's tiles as selected
func set_selected(is_selected: bool):
	for tile in self.get_children():
		tile.set_selected(is_selected)

# Triggers when clicking on the car (one of its tiles)
func on_click(tile_clicked : Tile) -> void:
	get_parent().on_click(self, tile_clicked)

# Applies the texture to the car's tiles
func draw_car() -> String:
	var children = get_children()
	children.sort_custom(self, 'compare_placement')
	var i = 0
	for tile in children:
		if i < length:
			if not chosen_texture or tile.apply_texture(path + chosen_texture, i) == 'err':
				print('Error rendering car: ' + color)
				return 'err'
		i += 1
	return 'ok'

func compare_placement(tile1, tile2):
	if direction:
		return tile1.get_tile_string_pos() > tile2.get_tile_string_pos()
	else:
		return tile1.get_tile_string_pos() < tile2.get_tile_string_pos()
	
# Get a list of the file name's in a directory
func get_list_in_dir(path) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".import"):
				file = file.rstrip(".import")
			files.append(file)
	dir.list_dir_end()
	return files

# Moves the car's tiles forward or backward
func move_tiles(is_forward : bool):
	for tile in get_children():
		tile.move(is_forward)

# Returns true if the car is not blocked by other cars, otherwise false
func can_move(is_forward : bool):
	if is_forward:
		var front : Tile = self.get_child(0)
		return !front.is_colliding(is_forward) and front.can_move(is_forward)
	else:
		var back : Tile = self.get_child(len(self.get_children()) - 1)
		return !back.is_colliding(is_forward) and back.can_move(is_forward)

# Moves the car forward of backward, calls the move_tiles function
func move(is_forward : bool):
	if can_move(is_forward):
		move_tiles(is_forward)

func get_tiles():
	return self.get_children()
