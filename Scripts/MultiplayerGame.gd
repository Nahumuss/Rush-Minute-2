extends Node2D

var BOARD_SCALE = Vector2(0.75, 0.75)
var socket : StreamPeerTCP = null
var level : String = ''
var main_board : Board = null # The player's board
var enemy_board : Board = null # The enemy's board
var enemy_name : RichTextLabel = RichTextLabel.new()
var wait_thread : Thread = Thread.new() # A thread for waiting for the game to start and listening
var update_thread : Thread = Thread.new() # A thread for updating the board after game's start
var undo_redo = UndoRedo.new() # An object monitoring the changes to the board's string in order to create the crtl+z and ctrl+y
var closed = false # Whether the window is closed or opened
var random_match_button : Button = null
var create_private_room : Button = null
var join_private_room : Button = null 
var username_edit : LineEdit = null
var menu_buttons : YSort = null

var config : ConfigFile = ConfigFile.new() # The config file object for reading and writing player data on the computer
var stats : VBoxContainer = VBoxContainer.new()
var moves_counter_label : RichTextLabel = RichTextLabel.new()
var avarage_accuracy_label : RichTextLabel = RichTextLabel.new()
var winrate_label : RichTextLabel = RichTextLabel.new()
var username = ""
var min_moves = 0
var moves = 0
var done_min_moves = 0
var done_moves = 0
var wins = 0
var loses = 0

var config_path = "user://stats.cfg"
var key = OS.get_unique_id() # A unique id for the mechine that is used as the encryption key

# Loads the screen initially
func _ready():
	connect_to_server()
	load_data()
	var back_button = preload('res://Prefabs/BackButton.tscn').instance()
	random_match_button = get_node("MenuButtons/Random")
	create_private_room = get_node("MenuButtons/Create/CreatePrivate")
	join_private_room = get_node("MenuButtons/Join/JoinPrivate")
	username_edit = get_node("MenuButtons/Username")
	username_edit.text = username
	random_match_button.connect('pressed', self, 'join_random')
	create_private_room.connect('pressed', self, 'create_private')
	join_private_room.connect("pressed", self, 'join_private')
	add_child(back_button)
	wait_thread.start(self, "wait_for_start")

# Connects to the server
func connect_to_server():
	socket = StreamPeerTCP.new()
	if socket.connect_to_host('itaynh.ddns.net', 5635) == OK:
		pass
	else:
		socket.disconnect_from_host()

# Sends a request to create a private game
func create_private():
	on_choice()
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
		socket.put_data('C;'.to_utf8())

# Sends a request to join a private lobby	
func join_private():
	on_choice()
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
		socket.put_data(('P;' + get_node("MenuButtons/Join/PrivateID").text).to_utf8())

# Sends a request to join the random lobby
func join_random():
	on_choice()
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
		socket.put_data('R;'.to_utf8())

# Waits for the game to start and initiate the board
func wait_for_start(args):
	var infos = 0
	var sent = false
	while not closed and infos < 2:
		if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
			if socket.get_available_bytes() > 0:
				var message = socket.get_utf8_string(socket.get_available_bytes()).split(';')
				var prefix = message[0]
				var content = message[1]
				if prefix == 'U' and len(content) == 39:
					var board_infos = content.split('%')
					infos += 1
					level = board_infos[0]
					min_moves = int(board_infos[1])
				elif prefix == 'N':
					enemy_name.text = "Versing: " + content
					infos += 1
				elif prefix == 'C':
					get_node("MenuButtons/Create/PrivateID").text = content
	if closed:
		return
	
	# Game starts
	get_node("MenuButtons").hide()

	main_board = preload("res://Prefabs/Board.tscn").instance()
	main_board.name = 'Board'
	add_child(main_board)
	main_board.scale = BOARD_SCALE
	main_board.position = Vector2((1 - BOARD_SCALE.x) * 64 * 6,0)
	main_board.generate_from_string(level)

	enemy_board = preload("res://Prefabs/Board.tscn").instance()
	enemy_board.name = 'EnemeyBoard'
	add_child(enemy_board)
	enemy_board.scale = Vector2(1,1) - BOARD_SCALE
	enemy_board.position = Vector2(0, 64 * (4.5 - enemy_board.scale.y * 6))
	enemy_board.generate_from_string(level)
	
	
	enemy_name.rect_min_size = Vector2(0,30)
	moves_counter_label.rect_min_size = Vector2(0,15)
	moves_counter_label.text = "Moves: " + str(moves)
	avarage_accuracy_label.rect_min_size = Vector2(0,30)
	avarage_accuracy_label.text = "Accuracy: " + ((str(stepify(done_min_moves / float(done_moves) * 100.0, 0.1)) + '%') if done_moves != 0 else 'NAN')
	winrate_label.rect_min_size = Vector2(0,30)
	winrate_label.text = "Winrate: " + ((str(stepify(wins / float(wins + loses) * 100.0, 0.1)) + '%') if wins + loses != 0 else 'NAN')
	stats.set_position(Vector2(4,50))
	stats.set_size(Vector2((1 - BOARD_SCALE.x) * 64 * 6 - 8, 64 * (4.5 - enemy_board.scale.y * 6) - 50))
	stats.add_child(enemy_name)
	stats.add_child(moves_counter_label)
	stats.add_child(avarage_accuracy_label)
	stats.add_child(winrate_label)
	for child in stats.get_children():
		var text = child.text
		child.set_use_bbcode(true)
		child.set_bbcode("[font=res://Fonts/statsfont.tres]"+text+"[/font]")
	add_child(stats)
	
	update_thread.start(self, "listen_loop")

# Loads the player stats from the file
func load_data() -> void:
	config = ConfigFile.new()
	var err = config.load_encrypted_pass(config_path, key)
	if err == OK:
		username = config.get_value("user", "name", "")
		username = config.get_value("user", "name", "")
		wins = config.get_value("user", "wins", 0)
		loses = config.get_value("user", "loses", 0)
		done_min_moves = int(config.get_value("user", "min_moves", 0))
		done_moves = int(config.get_value("user", "done_moves", 0))

# Triggered after clicked any button on the multiplayer menu, sends the username
func on_choice() -> void:
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host() and username_edit.text != '':
		self.username = username_edit.text
		socket.put_data(('N;' + username_edit.text).to_utf8())
		config.set_value("user", "name", username_edit.text)

func end_game() -> void:
	close()
	get_tree().change_scene("res://TitleScreen.tscn")

# The main listen loop, waiting for the server to send board updates or game updates
func listen_loop(args):
	while not closed:
		if socket.get_status() != StreamPeerTCP.STATUS_ERROR and socket.is_connected_to_host():
			if socket.get_available_bytes() > 0:
				var message = socket.get_utf8_string(socket.get_available_bytes()).split(';')
				var prefix = message[0]
				var content = ''
				if message.size() == 2:
					content = message[1]
				if prefix == 'W':
					config.set_value("user", "wins", wins + 1)
					config.set_value("user", "min_moves", done_min_moves + min_moves)
					config.set_value("user", "done_moves", done_moves + moves)
					main_board.win()
				elif prefix == 'D':
					print('hi')
					config.set_value("user", "wins", wins + 1)
					main_board.win()
				elif prefix == 'L':
					config.set_value("user", "loses", loses + 1)
					enemy_board.win()
				elif prefix == 'U':
					if enemy_board.update_board_from_string(content) == 'err':
						enemy_board.hard_reset()
						enemy_board.generate_from_string(content)
		else:
			break

# Returns whether the board clicked is the main board or the enemie's
func on_click(board : Board):
	return board == main_board

# Trigged on window close / game end, saves the data
func close():
	config.save_encrypted_pass(config_path, key)
	closed = true
	socket.disconnect_from_host()

# Triggered on a key input
func _input(event):
	if main_board:
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
	moves_counter_label.set_bbcode("[font=res://Fonts/statsfont.tres]"+"Moves: " + str(moves)+"[/font]")

# Update the main board's string and sends it to the server
func update_main_board():
	main_board.update_board_from_string(main_board.level)
	send_main_board()

# Sends the updated board to the server
func send_main_board():
	socket.put_data(('U;' + main_board.level).to_utf8())
