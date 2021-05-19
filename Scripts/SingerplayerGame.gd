extends Node2D

var BOARD_SCALE = Vector2(0.75, 0.75)
var main_board : Board = null
var undo_redo = UndoRedo.new()
var config = null
var done_min_moves = 0
var done_moves = 0
var moves = 0
var stats : VBoxContainer = VBoxContainer.new()
var moves_counter_label : RichTextLabel = RichTextLabel.new()
var avarage_accuracy_label : RichTextLabel = RichTextLabel.new()

var config_path = "user://stats.cfg"
var key = OS.get_unique_id()

func _ready():
	load_data()
	var back_button = preload('res://Prefabs/BackButton.tscn').instance()
	add_child(back_button)
	main_board = preload("res://Prefabs/Board.tscn").instance()
	main_board.name = 'Board'
	add_child(main_board)
	main_board.scale = BOARD_SCALE
	main_board.position = Vector2(4/3 * 6 * 64 - BOARD_SCALE.x * 6 * 64,0)
	main_board.generate_tiles()
	
	moves_counter_label.rect_min_size = Vector2(0,20)
	moves_counter_label.text = "Moves: " + str(moves)
	avarage_accuracy_label.rect_min_size = Vector2(0,30)
	avarage_accuracy_label.text = "Accuracy: " + ((str(stepify(done_min_moves / float(done_moves) * 100.0, 0.1)) + '%') if done_moves != 0 else 'NAN')
	stats.set_position(Vector2(4,50))
	stats.set_size(Vector2((1 - BOARD_SCALE.x) * 64 * 6 - 8, 64 * 4.5 - 50))
	stats.add_child(moves_counter_label)
	stats.add_child(avarage_accuracy_label)
	for child in stats.get_children():
		var text = child.text
		child.set_use_bbcode(true)
		child.set_bbcode("[font=res://Fonts/statsfont.tres]"+text+"[/font]")
	add_child(stats)

func load_data() -> void:
	config = ConfigFile.new()
	var err = config.load_encrypted_pass(config_path, key)
	if err == OK:
		done_min_moves = int(config.get_value("user", "min_moves", 0))
		done_moves = int(config.get_value("user", "done_moves", 0))

func on_click(var board):
	return true
	
func end_game() -> void:
	config.set_value("user", "min_moves", done_min_moves + main_board.min_moves)
	config.set_value("user", "done_moves", done_moves + moves)
	done_min_moves += main_board.min_moves
	done_moves += moves
	moves = 0
	moves_counter_label.set_bbcode("[font=res://Fonts/statsfont.tres]"+"Moves: 0"+"[/font]")
	avarage_accuracy_label.set_bbcode("[font=res://Fonts/statsfont.tres]"+"Accuracy: " + ((str(stepify(done_min_moves / float(done_moves) * 100.0, 0.1)) + '%') if done_moves != 0 else 'NAN')+"[/font]")
	main_board.start_new_level()
	config.save_encrypted_pass(config_path, key)

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
				moves += 1
		if event.scancode == KEY_R:
			main_board.hard_reset()
			main_board.generate_from_string(main_board.level_start)
			undo_redo.clear_history()
			moves += 1
		if event.scancode == KEY_Z and Input.is_key_pressed(KEY_CONTROL) and undo_redo.has_undo():
			undo_redo.undo()
			moves += 1
		elif event.scancode == KEY_Y and Input.is_key_pressed(KEY_CONTROL) and undo_redo.has_redo():
			undo_redo.redo()
			moves += 1
		moves_counter_label.set_bbcode("[font=res://Fonts/statsfont.tres]"+ "Moves: " + str(moves)+"[/font]")
	if str(main_board)[17] == 'A':
		main_board.win()
		
func close():
	config.save_encrypted_pass(config_path, key)
		
func update_main_board():
	main_board.update_board_from_string(main_board.level)
