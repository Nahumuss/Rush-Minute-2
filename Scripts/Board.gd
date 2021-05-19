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
	

# Generating the tiles
func generate_tiles() -> void:
	var text : String = load_text_file('res://Levels/levels.txt')
	var levels : Array = text.split("\n")
	level = get_random_level(levels)
	generate_from_string(level)

# Generating the tiles from a given string
func generate_from_string(tiles = level) -> void:
	level = tiles
	var cars_placement = {}
	for x in range(len(tiles) / DIMENTIONS.y):
		for y in range(len(tiles) / DIMENTIONS.x):
			var tile = tiles[x + y * DIMENTIONS.x]
			if tile != 'o':
				if tile == 'x':
					add_wall(Vector2(x,y))
				else:
					if cars_placement.has(tile):
						cars_placement[tile].append(Vector2(x,y))
					else:
						cars_placement[tile] = [Vector2(x,y)]
	for key in cars_placement.keys():
		add_car_auto(cars_placement[key], key)


func update_board_from_string(tiles = level) -> String:
	var changed_cars = []
	var current_level = to_string()
	for x in range(len(tiles) / DIMENTIONS.y):
		for y in range(len(tiles) / DIMENTIONS.x):
			var pos = x + y * DIMENTIONS.x
			var new_tile = tiles[pos]
			var old_tile = current_level[pos]
			if new_tile != old_tile and new_tile != 'x' and old_tile != 'x':
				if new_tile == 'o' or old_tile == 'o':
					if new_tile == 'o':
						var current_car = find_car_by_name(old_tile)
						if not current_car:
							return 'err'
						if remove_car_tile(current_car, pos) == 'err':
							return 'err'
						if not current_car in changed_cars:
							changed_cars.append(current_car)
					else:
						var current_car : Car = find_car_by_name(new_tile)
						if not current_car:
							return 'err'
						current_car.add_tile(Vector2(x,y))
						if not current_car in changed_cars:
							changed_cars.append(current_car)
						changed_cars.append(current_car)
				else:
					return 'err'
	level = tiles
	return refresh_cars(changed_cars)
	
func refresh_cars(cars) -> String:
	for car in cars:
		if car is Car:
			if car == selected_car:
				car.set_selected(true)
			if car.draw_car() == 'err':
				return 'err'
			car.fix_rotation()
	return 'ok'

func remove_car_tile(car : Car, tile_pos : int) -> String:
	for car_tile in car.get_tiles():
		if car_tile.get_tile_string_pos() == tile_pos:
			car.remove_child(car_tile)
			return 'ok'
	return 'err'

func find_car_by_name(name) -> Car:
	for child in get_children():
		if child is Car:
			if name == child.color:
				return child
	return null

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
	if get_parent().on_click(self):
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
	car.init(tiles_pos, rotated, name)
	add_child(car)

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
		return ""
	var text = f.get_as_text()
	f.close()
	return text

# Triggered when winning
func win() -> void:
	var popup : PopupDialog = self.get_node('WinMessage')
	var popup_timer : Timer = popup.get_child(0)
	popup_timer.connect('timeout', popup, 'hide')
	popup_timer.connect('timeout', self.get_parent(), 'end_game')
	popup_timer.start()
	popup.set_as_toplevel(true)
	popup.popup()
	popup.set_as_toplevel(false)
	selected_car = null

func _to_string():
	var board_string = 'oooooooooooooooooooooooooooooooooooo'
	for child in get_children():
		if child is Car or child is Wall:
			for tile in child.get_tiles():
				board_string[tile.get_tile_string_pos()] = child.color
	return board_string
			
