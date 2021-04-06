extends Node2D

var BOARD_SCALE = Vector2(0.75, 0.75)
var main_board = null
var undo_redo = UndoRedo.new()

func _ready():
	var back_button = preload('res://Prefabs/BackButton.tscn').instance()
	add_child(back_button)
	main_board = preload("res://Prefabs/Board.tscn").instance()
	main_board.name = 'Board'
	add_child(main_board)
	main_board.scale = BOARD_SCALE
	main_board.position = Vector2(4/3 * 6 * 64 - BOARD_SCALE.x * 6 * 64,0)
	main_board.generate_tiles()
	
func on_click(var board):
	return true

# Triggered on a key input
func _input(event):
	var timer : Timer = main_board.get_child(1)
	if event is InputEventKey and event.pressed and timer.time_left == 0:
		timer.start()
		if main_board.selected_car:
			var can_move = false
			var forward = false
			if event.scancode == KEY_W or event.scancode == KEY_UP or event.scancode == KEY_D or event.scancode == KEY_RIGHT:
				if main_board.selected_car.can_move(true):
					can_move = true
					forward = true
			if event.scancode == KEY_S or event.scancode == KEY_DOWN or event.scancode == KEY_A or event.scancode == KEY_LEFT:
				if main_board.selected_car.can_move(false):
					can_move = true
					forward = false
			if can_move:
				undo_redo.create_action('Move car')
				undo_redo.add_undo_property(main_board, 'level', main_board.level)
				undo_redo.add_undo_method(self, 'update_main_board')
				main_board.selected_car.move(forward)
				main_board.level = str(main_board)
				undo_redo.add_do_property(main_board, 'level', main_board.level)
				undo_redo.add_do_method(self, 'update_main_board')
				undo_redo.commit_action()
		if event.scancode == KEY_R:
			main_board.soft_reset()
			undo_redo.clear_history()
		if event.scancode == KEY_Z and Input.is_key_pressed(KEY_CONTROL):
			undo_redo.undo()
		elif event.scancode == KEY_Y and Input.is_key_pressed(KEY_CONTROL):
			undo_redo.redo()
	if str(main_board)[17] == 'A':
		main_board.win(true)
		
func close():
	pass
		
func update_main_board():
	main_board.update_board_from_string(main_board.level)
