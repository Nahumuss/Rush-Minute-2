extends Node2D

var BOARD_SCALE = Vector2(0.75, 0.75)
var socket : StreamPeerTCP = null
var level : String = ''
var main_board : Board = null
var enemy_board : Board = null
var enemy_name : RichTextLabel = RichTextLabel.new()
var wait_thread : Thread = Thread.new()
var wait_answer_thread : Thread = Thread.new()
var update_thread : Thread = Thread.new()
var undo_redo = UndoRedo.new()
var closed = false
var random_match_button : Button = null
var create_private_room : Button = null
var join_private_room : Button = null 
var username_edit : LineEdit = null
var menu_buttons : YSort = null
var stats : VBoxContainer = VBoxContainer.new()
var moves_counter : RichTextLabel = RichTextLabel.new()
var username = ""
var moves = 0

func _ready():
	connect_to_server()
	var back_button = preload('res://Prefabs/BackButton.tscn').instance()
	random_match_button = get_node("MenuButtons/Random")
	create_private_room = get_node("MenuButtons/Create/CreatePrivate")
	join_private_room = get_node("MenuButtons/Join/JoinPrivate")
	username_edit = get_node("MenuButtons/Username")
	random_match_button.connect('pressed', self, 'join_random')
	create_private_room.connect('pressed', self, 'create_private')
	join_private_room.connect("pressed", self, 'join_private')
	add_child(back_button)
	wait_thread.start(self, "wait_for_start")

func connect_to_server():
	socket = StreamPeerTCP.new()
	if socket.connect_to_host('itaynh.ddns.net', 5635) == OK:
		pass
	else:
		socket.disconnect_from_host()

func create_private():
	on_choice()
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
		socket.put_data('C;'.to_utf8())
		
func join_private():
	on_choice()
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
		socket.put_data(('P;' + get_node("MenuButtons/Join/PrivateID").text).to_utf8())

func join_random():
	on_choice()
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
		socket.put_data('R;'.to_utf8())

func wait_for_start(args):
	var infos = 0
	var sent = false
	while not closed and infos < 2:
		if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
			if socket.get_available_bytes() > 0:
				var message = socket.get_utf8_string(socket.get_available_bytes()).split(';')
				print(message)
				var prefix = message[0]
				var content = message[1]
				if prefix == 'U' and len(content) == 36:
					infos += 1
					level = content
				elif prefix == 'N':
					enemy_name.text = "Versing: " + content
					infos += 1
				elif prefix == 'C':
					get_node("MenuButtons/Create/PrivateID").text = content
	if closed:
		print('closed')
		return
		
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
	
	enemy_name.rect_min_size = Vector2(0,40)
	moves_counter.rect_min_size = Vector2(0,20)
	moves_counter.text = "Moves: " + str(moves)
	stats.set_position(Vector2(2,50))
	stats.set_size(Vector2((1 - BOARD_SCALE.x) * 64 * 6 - 4, 64 * (4.5 - enemy_board.scale.y * 6) - 50))
	stats.add_child(enemy_name)
	stats.add_child(moves_counter)
	add_child(stats)
	
	update_thread.start(self, "update_enemy_board")

func on_choice() -> void:
	print(username_edit.text)
	if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host() and username_edit.text != '':
		self.username = username_edit.text
		socket.put_data(('N;' + username_edit.text).to_utf8())

func end_game() -> void:
	close()
	get_tree().change_scene("res://TitleScreen.tscn")

func update_enemy_board(args):
	while not closed:
		if socket.get_status() == StreamPeerTCP.STATUS_ERROR:
			print(socket.get_status())
		if not socket.is_connected_to_host():
			print(socket.is_connected_to_host())
		if socket.get_status() != StreamPeerTCP.STATUS_ERROR and socket.is_connected_to_host():
			if socket.get_available_bytes() > 0:
				var message = socket.get_utf8_string(socket.get_available_bytes()).split(';')
				print(message)
				var prefix = message[0]
				var content = ''
				if message.size() == 2:
					content = message[1]
				if prefix == 'W':
					main_board.win()
				elif prefix == 'L':
					enemy_board.win()
				elif prefix == 'U':
					print('New board = ' + content)
					if enemy_board.update_board_from_string(content) == 'err':
						print("ERROR")
						enemy_board.hard_reset()
						enemy_board.generate_from_string(content)
		else:
			print("Disconnected")
			break
	print('closed')

func on_click(board : Board):
	return board == main_board
	
func close():
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
				main_board.soft_reset()
				undo_redo.clear_history()
				moves += 1
			if event.scancode == KEY_Z and Input.is_key_pressed(KEY_CONTROL) and undo_redo.has_undo():
				undo_redo.undo()
				moves += 1
			elif event.scancode == KEY_Y and Input.is_key_pressed(KEY_CONTROL) and undo_redo.has_redo():
				undo_redo.redo()
				moves += 1
	moves_counter.text = "Moves: " + str(moves)

func update_main_board():
	main_board.update_board_from_string(main_board.level)
	send_main_board()

func send_main_board():
	print(socket.is_connected_to_host())
	socket.put_data(('U;' + main_board.level).to_utf8())
	print('meow')
