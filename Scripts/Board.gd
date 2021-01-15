extends Node2D
class_name Board

#The dimentions of the board
const DIMENTIONS = Vector2(6,6)
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
#The car that was last clicked by the player
var selected_car : Car = null

func _ready():
	rng.randomize()
	generate_tiles()

#Generating the tiles randomly - for now
func generate_tiles() -> void:
#	add_car_auto([Vector2(0,0), Vector2(0,1)])
#	add_car_auto([Vector2(1,0), Vector2(2,0)])
#	add_car_auto([Vector2(0,2), Vector2(0,3)])
#	add_car_auto([Vector2(1,2), Vector2(2,2)])
#	add_car_auto([Vector2(3,1), Vector2(3,2)])
#	add_car_auto([Vector2(4,1), Vector2(5,1)])
#	add_car_auto([Vector2(0,4), Vector2(1,4)])
#	add_car_auto([Vector2(0,5), Vector2(1,5)])
#	add_car_auto([Vector2(2,3), Vector2(2,4)])
#	add_car_auto([Vector2(2,5), Vector2(3,5), Vector2(4,5)])
#	add_car_auto([Vector2(3,3), Vector2(4,3)])
#	add_car_auto([Vector2(5,3), Vector2(5,4), Vector2(5,5)])
#
#	add_wall(Vector2(3,0))
	generate_from_string('IBBxooIooLDDJAALooJoKEEMFFKooMGGHHHM')
	
func generate_from_string(tiles) -> void:
	var cars = {}
	for x in range(len(tiles) / DIMENTIONS.y):
		for y in range(len(tiles) / DIMENTIONS.x):
			var tile = tiles[x + y * DIMENTIONS.x]
			if tile != 'o':
				if tile == 'x':
					add_wall(Vector2(x,y))
				elif cars.has(tile):
					cars[tile].append(Vector2(x,y))
				else:
					cars[tile] = [Vector2(x,y)]
	for key in cars.keys():
		add_car_auto(cars[key])

#When clicking the car
func on_click(car_clicked : Car, tile_clicked : Tile) -> void:
	if selected_car != car_clicked:
		car_clicked.set_selected(true)
		if selected_car:
			selected_car.set_selected(false)
		selected_car = car_clicked

func add_wall(pos : Vector2):
	var wall : Wall = preload("res://Prefabs/Wall.tscn").instance()
	wall.init(pos)
	add_child(wall)

func add_car_auto(tiles_pos : Array):
	if len(tiles_pos) <= 1:
		add_car(tiles_pos, false)
	else:
		add_car(tiles_pos, tiles_pos[1] - tiles_pos[0] == Vector2(1,0))

func add_car(tiles_pos : Array, rotated : bool):
	var car : Car = preload("res://Prefabs/Car.tscn").instance()
	car.init(tiles_pos, rotated)
	add_child(car)

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
			
func get_random_number(min_val : int, max_val : int) -> int:
	return rng.randi_range(min_val, max_val)
	
func load_text_file(path):
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		printerr("Could not open file, error code ", err)
		return ""
	var text = f.get_as_text()
	f.close()
	return text
