extends Button


func _ready():
	connect('pressed', self, 'on_click')
	
func on_click():
	get_parent().close()
	get_tree().change_scene("res://TitleScreen.tscn")
