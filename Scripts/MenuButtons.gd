extends YSort

const window_size = Vector2(384,288) 

func _ready():
	for child in get_children():
		child.rect_position.x = window_size.x / 2 - child.rect_size.x / 2
