extends Node2D
class_name Wall


func _ready():
	pass

# Called on the wall's initialization
func init(pos : Vector2):
	var tile : Tile = load("res://Prefabs/Tile.tscn").instance()
	tile.set_tile_board_pos(pos)
	self.add_child(tile)
	tile.apply_texture('res://Sprites/box.png', 0)

# Triggers when clicking on the wall
func on_click(tile : Tile):
	pass
