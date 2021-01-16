extends Node2D
class_name Board

# The dimentions of the board
const DIMENTIONS = Vector2(6,6)

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

# The current level string
var level = ''

# The car that was last clicked by the player
var selected_car : Car = null

func _ready():
	rng.randomize()
	generate_tiles()

# Generating the tiles
func generate_tiles() -> void:
	var text : String = load_text_file('res://Levels/levels.txt')
	var levels : Array = text.split("\n")
	level = get_random_level(levels)
	generate_from_string(level)

# Generating the tiles from a given string
func generate_from_string(tiles) -> void:
	var cars = {}
	for x in range(len(tiles) / DIMENTIONS.y):
		for y in range(len(tiles) / DIMENTIONS.x):
			var tile = tiles[x + y * DIMENTIONS.x]
			if tile != 'o':
				if tile == 'x':
					add_wall(Vector2(x,y))
				else:
					if cars.has(tile):
						cars[tile].append(Vector2(x,y))
					else:
						cars[tile] = [Vector2(x,y)]
	for key in cars.keys():
			add_car_auto(cars[key], key)

# Removes all cars from the board
func hard_reset() -> void:
	for child in get_children():
		if child is Car or child is Wall:
			remove_child(child)

# Returns the cars to their original position
func soft_reset() -> void:
	for child in get_children():
		if child is Car:
			child.reset();

# Gets a random level form the levels list
func get_random_level(levels):
	return levels[get_random_number(0,len(levels))].split(' ')[1]

# Called when clicking the car
func on_click(car_clicked : Car, tile_clicked : Tile) -> void:
	if selected_car != car_clicked:
		car_clicked.set_selected(true)
		if selected_car:
			selected_car.set_selected(false)
		selected_car = car_clicked

# Adds a wall to the board
func add_wall(pos : Vector2):
	var wall : Wall = preload("res://Prefabs/Wall.tscn").instance()
	wall.init(pos)
	add_child(wall)

# Adds a car and oriantate by the tiles given
func add_car_auto(tiles_pos : Array, name : String = ''):
	if len(tiles_pos) <= 1:
		add_car(tiles_pos, false, name)
	else:
		add_car(tiles_pos, tiles_pos[1] - tiles_pos[0] == Vector2(1,0), name)

# Adds a car
func add_car(tiles_pos : Array, rotated : bool, name : String = ''):
	var car : Car = null
	if name == 'A':
		car = preload("res://Prefabs/RedCar.tscn").instance()
	else:
		car = preload("res://Prefabs/Car.tscn").instance()
	car.init(tiles_pos, rotated)
	add_child(car)

# Triggered on a key input
func _input(event):
	var timer : Timer = get_child(1)
	if event is InputEventKey and event.pressed and timer.time_left == 0:
		timer.start()
		if event.scancode == KEY_W or event.scancode == KEY_UP or event.scancode == KEY_D or event.scancode == KEY_RIGHT:
			if selected_car:
				selected_car.move(true)
		if event.scancode == KEY_S or event.scancode == KEY_DOWN or event.scancode == KEY_A or event.scancode == KEY_LEFT:
			if selected_car:
				selected_car.move(false)
		if event.scancode == KEY_R:
			soft_reset()
		if event.scancode == KEY_B:
			start_new_level()

# Starts a new level
func start_new_level() -> void:
	hard_reset()
	generate_tiles()

# Gets a random number
func get_random_number(min_val : int, max_val : int) -> int:
	return rng.randi_range(min_val, max_val)

# Loads a text file to the code
func load_text_file(path) -> String:
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file, error code ", err)
		return ""
	var text = f.get_as_text()
	f.close()
	return text

# Triggered when winning
func win() -> void:
	var popup : PopupDialog = get_node("WinMessage")
	var popup_timer : Timer = popup.get_child(0)
	popup_timer.connect('timeout', popup, 'hide')
	popup_timer.connect('timeout', self, 'start_new_level')
	popup_timer.set_wait_time(1)
	popup_timer.start()
	get_node("WinMessage").popup()
	selected_car = null
