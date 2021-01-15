extends Area2D

# Triggers when clicking on the Area2D of the tile
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		self.on_click()

# Triggers when clicking on the Area2D
func on_click():
	get_parent().on_click()
