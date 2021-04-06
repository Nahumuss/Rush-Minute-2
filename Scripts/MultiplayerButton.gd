extends Button


func _ready():
	connect('pressed', self, 'on_click')
	
func on_click():
	get_tree().change_scene("res://MultiplayerGame.tscn")
