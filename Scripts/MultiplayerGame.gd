extends Node2D

var BOARD_SCALE = Vector2(0.75, 0.75)
var socket : StreamPeerTCP = null
var level : String = ''
var main_board : Board = null
var enemy_board : Board = null
var wait_thread : Thread = Thread.new()
var update_thread : Thread = Thread.new()

func _ready():
	load_board()

func load_board():
	socket = StreamPeerTCP.new()
	if socket.connect_to_host("itaynh.ddns.net", 5635) == OK:
		wait_thread.start(self, "wait_for_start")
	else:
		pass #TODO

func wait_for_start(args):
	var level
	while true:
		level = socket.get_utf8_string(37)
		if len(level) == 37:
			print(level)
			break

	main_board = preload("res://Prefabs/Board.tscn").instance()
	add_child(main_board)
	main_board.scale = BOARD_SCALE
	main_board.generate_from_string(level)

	enemy_board = preload("res://Prefabs/Board.tscn").instance()
	add_child(enemy_board)
	enemy_board.scale = Vector2(1,1) - BOARD_SCALE
	enemy_board.position = Vector2(BOARD_SCALE.x * 64 * 6,0)
	enemy_board.generate_from_string(level)
	update_thread.start(self, "update_enemy_board")

func update_enemy_board(args):
	while true:
		if socket:
			var new_board = socket.get_utf8_string(36)
			print('New board = ' + new_board)
			if enemy_board.update_board_from_string(new_board) == 'err':
				print("ERROR")
				enemy_board.hard_reset()
				enemy_board.generate_from_string(new_board)

func on_click(board : Board):
	if board == main_board:
		return true
	return false

# Triggered on a key input
func _input(event):
	if main_board:
		var timer : Timer = main_board.get_child(1)
		if event is InputEventKey and event.pressed and timer.time_left == 0:
			timer.start()
			if main_board.selected_car:
				if event.scancode == KEY_W or event.scancode == KEY_UP or event.scancode == KEY_D or event.scancode == KEY_RIGHT:
					if main_board.selected_car.can_move(true):
						main_board.selected_car.move(true)
						update_main_board()
				if event.scancode == KEY_S or event.scancode == KEY_DOWN or event.scancode == KEY_A or event.scancode == KEY_LEFT:
					if main_board.selected_car.can_move(false):
						main_board.selected_car.move(false)
						update_main_board()
			if event.scancode == KEY_R:
				main_board.soft_reset()
				update_main_board()
			
func update_main_board():
	var level = main_board.to_string()
	socket.put_utf8_string(level)
