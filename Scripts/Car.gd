extends Node2D
class_name Car

var length = 0
var direction : bool = false # Vertical if true
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

func _ready():
	pass
	
func init(tiles_pos : Array, direction : bool) -> void:
	rng.randomize()
	if direction:
		tiles_pos.invert()
	for tile_pos in tiles_pos:
		var tile : Tile = load("res://Prefabs/Tile.tscn").instance()
		tile.set_tile_board_pos(Vector2(tile_pos.x,tile_pos.y))
		self.add_child(tile)
	self.direction = direction
	self.length = len(tiles_pos)
	fix_rotation()
	draw_car()

func fix_rotation() -> void:
	for tile in get_children():
		var last_rotation = tile.get_rotation_degrees()
		if direction and last_rotation != 90:
			tile.set_rotation(deg2rad(90))
		elif direction and last_rotation != 0:
			tile.set_rotation(90)

func set_selected(is_selected: bool):
	for tile in self.get_children():
		tile.set_selected(is_selected)

func on_click(tile_clicked : Tile) -> void:
	get_parent().on_click(self, tile_clicked)

func draw_car() -> void:
	var path : String = "res://Sprites/Cars/" + str(length) + "x1/"
	var textures : Array = get_list_in_dir(path)
	if len(textures) > 0:
		var chosen = textures[rng.randi_range(0,len(textures) - 1)]
		for i in range(length):
			self.get_children()[i].apply_texture(path + chosen, i)
	
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

func move_tiles(is_forward : bool):
	for tile in get_children():
		tile.move(is_forward)

func can_move(is_forward : bool):
	if is_forward:
		var front : Tile = self.get_child(0)
		return !front.is_colliding(is_forward) and front.can_move(is_forward)
	else:
		var back : Tile = self.get_child(len(self.get_children()) - 1)
		return !back.is_colliding(is_forward) and back.can_move(is_forward)

func move(is_forward : bool):
	if can_move(is_forward):
		move_tiles(is_forward)
