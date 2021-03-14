extends Node2D
class_name Wall

var tiles : Array = []
var color = ''

func _ready():
	pass

# Called on the wall's initialization
func init(pos : Vector2, color = 'x'):
	var tile : Tile = load("res://Prefabs/Tile.tscn").instance()
	tile.set_tile_board_pos(pos)
	self.add_child(tile)
	tile.apply_texture('res://Sprites/box.png', 0)
	tiles.append(tile)
	self.color = color

# Triggers when clicking on the wall
func on_click(tile : Tile):
	pass
	
func get_tiles():
	return tiles
