extends Node2D
class_name Tile

# Emitted when a piece is removed
signal remove_piece

# Emitted when a piece is added
signal add_piece

onready var forward_ray : RayCast2D = get_node("Forward")
onready var backward_ray : RayCast2D = get_node("Backward")

var piece = {
	"exists": false,
	"piece": null
}

func _ready():
	forward_ray.add_exception(self.get_child(0))
	backward_ray.add_exception(self.get_child(0))

func get_tile_pos() -> Vector2:
	return position

func set_tile_pos(new_pos: Vector2) -> void:
	position = new_pos

func get_tile_board_pos() -> Vector2:
	var pos = get_tile_pos()
	return Vector2(int(pos.x / 64), int(pos.y / 64))

func set_tile_board_pos(new_pos: Vector2) -> void:
	set_tile_pos(new_pos * 64 + Vector2(32,32))

func set_selected(is_selected: bool):
	var sprite : Sprite = get_child(0).get_child(1)
	if is_selected:
		sprite.modulate = Color(0,0,1)
	else:
		sprite.modulate = Color(1,1,1)

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

func on_click() -> void:
	get_parent().on_click(self)
	
	
func move(is_forward : bool):
	var direction : Vector2 = forward_ray.cast_to - forward_ray.position if is_forward else backward_ray.cast_to - forward_ray.position
	var new_pos : Vector2 = position + (direction).rotated(self.rotation) * 2
	var border = 64 * get_tree().get_root().get_node("Board").DIMENTIONS
	self.position += (direction.rotated(self.rotation) / 33) * 64
	
func can_move(is_forward : bool) -> bool:
	var direction : Vector2 = forward_ray.cast_to - forward_ray.position if is_forward else backward_ray.cast_to - forward_ray.position
	var new_pos : Vector2 = position + (direction).rotated(self.rotation) * 2
	var border = 64 * get_tree().get_root().get_node("Board").DIMENTIONS
	return new_pos.x > 0 and new_pos.x < border.x and new_pos.y > 0 and new_pos.y < border.y
	
func is_colliding(is_forward : bool):
	if is_forward:
		return forward_ray.is_colliding() and forward_ray.get_collider() != self.get_child(0)
	else:
		return backward_ray.is_colliding() and backward_ray.get_collider() != self.get_child(0)
