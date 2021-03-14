extends Car
class_name RedCar

func _ready():
	._ready()

# Applies the texture to the car's tiles
func draw_car() -> void:
	var path : String = "res://Sprites/Cars/Red/"
	var textures : Array = get_list_in_dir(path)
	var chosen_texture = null
	if len(textures) > 0:
		chosen_texture = textures[rng.randi_range(0,len(textures) - 1)]
	var children = get_children()
	children.sort_custom(self, 'compare_placement')
	var i = 0
	for tile in children:
		if i < length:
			tile.apply_texture(path + chosen_texture, i)
		i += 1
			
# Moves the car forward of backward, calls the move_tiles function
func move(is_forward : bool):
	if .can_move(is_forward):
		.move_tiles(is_forward)
	elif is_forward and !self.get_child(0).can_move(is_forward):
		get_parent().win()
	
