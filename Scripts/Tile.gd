extends Node2D
class_name Tile

onready var forward_ray : RayCast2D = get_node("Forward") # The ray that is triggered if something is in front of the car
onready var backward_ray : RayCast2D = get_node("Backward") # The ray that is triggered if something is in the back of the car
var starting_point : Vector2 = Vector2(0,0) # The starting point of the car for reseting

func _ready():
	forward_ray.add_exception(self.get_child(0))
	backward_ray.add_exception(self.get_child(0))
	starting_point = get_tile_board_pos()

# Returns the tile's position by pixels
func get_tile_pos() -> Vector2:
	return position

# Sets the tile's position by pixels
func set_tile_pos(new_pos: Vector2) -> void:
	position = new_pos

# Returns the tile's position on board (in tiles)
func get_tile_board_pos() -> Vector2:
	var pos = get_tile_pos()
	return Vector2(int(pos.x / 64), int(pos.y / 64))

# Sets the tile's position on board (in tiles)
func set_tile_board_pos(new_pos: Vector2) -> void:
	set_tile_pos(new_pos * 64 + Vector2(32,32))

# Resets the tile's position
func reset() -> void:
	set_tile_board_pos(starting_point)

# Set's the tile as selected by changing its colour
func set_selected(is_selected: bool):
	var sprite : Sprite = get_child(0).get_child(1)
	if is_selected:
		sprite.modulate = Color(0,0,1)
	else:
		sprite.modulate = Color(1,1,1)

# Applies a texture to a tile, cropping the original car texture by its position
func apply_texture(texture_file, part) -> void:
	var sprite : Sprite = get_child(0).get_child(1)
	var texture : Texture = load(texture_file)
	var atlas = AtlasTexture.new()
	atlas.set_atlas(texture)
	var w = texture.get_width()
	atlas.region = Rect2(0, part * w, w, (part + 1) * w)
	sprite.set_texture(atlas)
	var scale = Vector2(64.0 / atlas.region.size.x, 64.0 / atlas.region.size.x)
	sprite.scale = scale

# Triggers when clicking on the tile
func on_click() -> void:
	get_parent().on_click(self)
	
# Moves the tile forward or backward
func move(is_forward : bool) -> void:
	var direction : Vector2 = forward_ray.cast_to - forward_ray.position if is_forward else backward_ray.cast_to - forward_ray.position
	var new_pos : Vector2 = position + (direction).rotated(self.rotation) * 2
	var border = 64 * get_tree().get_root().get_node("Game").get_node("Board").DIMENTIONS
	self.position += (direction.rotated(self.rotation) / 33) * 64

# Return's whether the tile can move or not by the board's size 
func can_move(is_forward : bool) -> bool:
	var direction : Vector2 = forward_ray.cast_to - forward_ray.position if is_forward else backward_ray.cast_to - forward_ray.position
	var new_pos : Vector2 = position + (direction).rotated(self.rotation) * 2
	var border = 64 * get_tree().get_root().get_node("Game").get_node("Board").DIMENTIONS
	return new_pos.x > 0 and new_pos.x < border.x and new_pos.y > 0 and new_pos.y < border.y

# Returns whether the car's rays are colliding with objects
func is_colliding(is_forward : bool):
	if is_forward:
		return forward_ray.is_colliding() and forward_ray.get_collider() != self.get_child(0)
	else:
		return backward_ray.is_colliding() and backward_ray.get_collider() != self.get_child(0)
		
func get_tile_string_pos() -> int:
	return 6 * (int(round(self.position.y) - 32)) / 64  + (int(round(self.position.x)) - 32) / 64
	
func _to_string():
	return str(get_tile_board_pos()) 
