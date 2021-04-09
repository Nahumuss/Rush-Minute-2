extends Node2D

var BOARD_SCALE = Vector2(0.75, 0.75)
var socket : StreamPeerTCP = null
var level : String = ''
var main_board : Board = null
var enemy_board : Board = null
var wait_thread : Thread = Thread.new()
var update_thread : Thread = Thread.new()
var undo_redo = UndoRedo.new()
var closed = false

export var websocket_url = "127.0.0.1"
var _client = WebSocketClient.new()
func _ready():
	var back_button = preload('res://Prefabs/BackButton.tscn').instance()
	add_child(back_button)
	load_board()

func load_board():
	socket = StreamPeerTCP.new()
	if socket.connect_to_host("itaynh.ddns.net", 5635) == OK:
		wait_thread.start(self, "wait_for_start")
	else:
		socket.disconnect_from_host()

func wait_for_start(args):
	while not closed:
		if socket.get_status() == StreamPeerTCP.STATUS_CONNECTED and socket.is_connected_to_host():
			print('Connected')
			level = socket.get_utf8_string(36)
			print(level)
			if len(level) == 36:
				print(level)
				break
	if closed:
		print('closed')
		return

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
	update_thread.start(self, "update_enemy_board")

func end_game() -> void:
	close()
	get_tree().change_scene("res://TitleScreen.tscn")

func update_enemy_board(args):
	while not closed:
		if socket.get_status() != StreamPeerTCP.STATUS_ERROR and socket.is_connected_to_host():
			var new_board = socket.get_utf8_string(36)
			if new_board == 'whyareyoutryingtocheat/readmycodebro':
				main_board.win()
				print('ez')
			elif new_board == 'lmfaololyoulostthatonerealhardgonext':
				enemy_board.win()
				print('hard')
			elif len(new_board) == 36:
				print('New board = ' + new_board)
				if enemy_board.update_board_from_string(new_board) == 'err':
					print("ERROR")
					enemy_board.hard_reset()
					enemy_board.generate_from_string(new_board)
		else:
			print("Disconnected")
	print('closed')

func on_click(board : Board):
	return board == main_board
	
func close():
	closed = true
	socket.disconnect_from_host()
	update_thread.wait_to_finish()

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
					send_main_board()
			if event.scancode == KEY_R:
				main_board.soft_reset()
				undo_redo.clear_history()
				send_main_board()
			if event.scancode == KEY_Z and Input.is_key_pressed(KEY_CONTROL):
				undo_redo.undo()
			elif event.scancode == KEY_Y and Input.is_key_pressed(KEY_CONTROL):
				undo_redo.redo()

func update_main_board():
	main_board.update_board_from_string(main_board.level)
	send_main_board()

func send_main_board():
	socket.put_utf8_string(main_board.level)
