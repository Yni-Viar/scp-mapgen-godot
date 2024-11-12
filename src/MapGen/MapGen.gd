extends Node3D
class_name FacilityGenerator

signal generated

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

@export var rng_seed: int = -1
## Rooms that will be used
@export var rooms: Array[MapGenZone]
## Map size
@export_range(8, 256, 2) var size: int = 8
## Room in grid size
@export var grid_size: float = 20.48
## Amount of zones (1 zones - 0, 2 zones - 1, e.t.c.)
@export var zones_amount: int = 0
## Large rooms support
@export var large_rooms: bool = false
## How much the map will be filled with rooms
@export_range(0.25, 2) var room_amount: float = 0.75
## Sets the door generation. Not recommended to disable, if your map uses SCP:SL 14.0-like door frames!
@export var enable_door_generation: bool = true
## Prints map seed
@export var debug_print: bool = false

var mapgen: Array[Array] = []
var disabled_points: Array[Vector2i] = []

class Room:
	# north, east, west and south check the connection between rooms.
	var exist: bool
	var north: bool
	var south: bool
	var east: bool
	var west: bool
	var room_type: RoomTypes
	var angle: float
	var large: bool

var size_y: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

## Prepares room generation
func prepare_generation() -> void:
	size_y = size * (zones_amount + 1)
	if rng_seed != -1:
		rng.seed = rng_seed
	# Fill mapgen with zeros
	for g in range(size):
		mapgen.append([])
		for h in range(size_y):
			mapgen[g].append(Room.new())
			mapgen[g][h].exist = false
			mapgen[g][h].north = false
			mapgen[g][h].south = false
			mapgen[g][h].east = false
			mapgen[g][h].west = false
			mapgen[g][h].room_type = RoomTypes.EMPTY
			mapgen[g][h].angle = 0
			mapgen[g][h].large = false
	generate_zone_astar()

## Main function, that generate the zones
func generate_zone_astar() -> void:
	var zone_counter: int = 0
	while zone_counter <= zones_amount:
		var number_of_rooms: int = size * room_amount
		# Bugfix - we need to center value for each zone.
		var tmp_1: float
		if (zone_counter % 2 == 1):
			tmp_1 = (zone_counter + 2 * zone_counter)
		else: # add one to be an odd number
			tmp_1 = (zone_counter + 1 + 2 * zone_counter)
		var zone_center: float = size_y * (tmp_1 / ((zones_amount + 1) * 2))
		# The center of the zone always exist
		mapgen[size / 2][roundi(zone_center)].exist = true
		# Center's coordinates
		var temp_x: int = size / 2
		var temp_y: int = roundi(zone_center)
		if number_of_rooms > (size - 2) * 4:
			printerr("Too many rooms, map won't spawn")
			return
		elif number_of_rooms < 1:
			printerr("Too few rooms, map won't spawn")
			return
		# Available room position (for AStar walk)
		var available_room_position: Array[Vector2] = [Vector2(0, size - 1),Vector2(size_y / (zones_amount + 1) * zone_counter, size_y / (zones_amount + 1) * (zone_counter + 1) - 1)]
		# Random room position. If large rooms enabled, also used for large room coordinates
		var random_room: Vector2
		## Reworked large rooms module
		if large_rooms && rooms[zone_counter].endrooms_single_large.size() > 0:
			var large_room_amount = size / 6
			for i in range(large_room_amount):
				while true:
					random_room = Vector2(rng.randi_range(available_room_position[0].x, available_room_position[0].y), rng.randi_range(available_room_position[1].x, available_room_position[1].y))
					if check_room_dimensions(random_room.x, random_room.y, 0):
						walk_astar(Vector2(temp_x, temp_y), random_room)
						mapgen[random_room.x][random_room.y].large = true
						break
		## Walk before need-to-spawn rooms runs out
		while number_of_rooms > 0:
			random_room = Vector2(rng.randi_range(available_room_position[0].x, available_room_position[0].y), rng.randi_range(available_room_position[1].x, available_room_position[1].y))
			walk_astar(Vector2(temp_x, temp_y), random_room)
			number_of_rooms -= 1
		## Connect two zones
		if zone_counter < zones_amount:
			var tmp_2: float
			if (zone_counter % 2 == 1):
				tmp_2 = (zone_counter + 2 + 2 * zone_counter)
			else: # add one to be an odd number
				tmp_2 = (zone_counter + 3 + 2 * zone_counter)
			zone_center = size_y * (tmp_2 / ((zones_amount + 1) * 2))
			walk_astar(Vector2(temp_x, temp_y), Vector2(temp_x, roundi(zone_center)))
		zone_counter += 1
	place_room_positions()

## Checks spawn places for large rooms in given coordinates
## type: 0 - room1, 1 - room2, 2 - room2C, 3 - room3
func check_room_dimensions(x: int, y: int, type: int) -> bool:
	match type:
		0: ## ROOM1 - endroom
			if x == 0 && y == 0:
				if !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x][y + 1].exist:
					disabled_points.append(Vector2i(x, y + 1))
					return true
				else:
					return false
			elif x == size - 1 && y == size_y - 1:
				if !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x - 1, y))
					return true
				elif !mapgen[x][y - 1].exist:
					disabled_points.append(Vector2i(x, y - 1))
					return true
				else:
					return false
			elif x == 0 && y == size_y - 1:
				if !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x][y - 1].exist:
					disabled_points.append(Vector2i(x, y - 1))
					return true
				else:
					return false
			elif x == size - 1 && y == 0:
				if !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x - 1, y))
					return true
				elif !mapgen[x][y + 1].exist:
					disabled_points.append(Vector2i(x, y + 1))
					return true
				else:
					return false
			## |[x][x]  |        |[x]
			## |[o][x]  |[o][x]  |[o]
			## |        |[x][x]  |[x]
			elif x == 0:
				if !mapgen[x][y + 1].exist && !mapgen[x + 1][y + 1].exist && !mapgen[x + 1][y].exist: 
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x + 1, y + 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x][y - 1].exist && !mapgen[x + 1][y - 1].exist && !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x + 1, y - 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x][y + 1].exist && !mapgen[x][y - 1].exist:
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x, y - 1))
					return true
				else:
					return false
			## [x][x]|        |  [x]|
			## [x][o]|  [x][o]|  [o]|
			##       |  [x][x]|  [x]|
			elif x == size - 1:
				if !mapgen[x][y + 1].exist && !mapgen[x - 1][y + 1].exist && !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x - 1, y + 1))
					disabled_points.append(Vector2i(x - 1, y))
					return true
				elif !mapgen[x][y - 1].exist && !mapgen[x - 1][y - 1].exist && !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x - 1, y - 1))
					disabled_points.append(Vector2i(x - 1, y))
					return true
				elif !mapgen[x][y + 1].exist && !mapgen[x][y - 1].exist:
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x, y - 1))
					return true
				else:
					return false
			## [x][x]   [x][x]   
			## [o][x]   [x][o]   [x][o][x]
			## ------   ------   ---------
			elif y == 0:
				if !mapgen[x][y + 1].exist && !mapgen[x + 1][y + 1].exist && !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x + 1, y + 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x - 1][y].exist && !mapgen[x - 1][y + 1].exist && !mapgen[x][y + 1].exist:
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x - 1, y + 1))
					disabled_points.append(Vector2i(x, y + 1))
					return true
				elif !mapgen[x + 1][y].exist && !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				else:
					return false
			## ------   ------   ---------  
			## [o][x]   [x][o]   [x][o][x]
			## [x][x]   [x][x]
			elif y == size_y - 1:
				if !mapgen[x + 1][y].exist && !mapgen[x + 1][y - 1].exist && !mapgen[x][y - 1].exist:
					disabled_points.append(Vector2i(x + 1, y))
					disabled_points.append(Vector2i(x + 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					return true
				elif !mapgen[x - 1][y].exist && !mapgen[x - 1][y - 1].exist && !mapgen[x][y - 1].exist:
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x - 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					return true
				elif !mapgen[x + 1][y].exist && !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				else:
					return false
			## [x][x]   [x][x]   [x][x][x]
			## [x][o]   [o][x]   [x][o][x]   [x][o][x]
			## [x][x]   [x][x]               [x][x][x]
			else:
				if !mapgen[x][y + 1].exist && !mapgen[x - 1][y + 1].exist && !mapgen[x - 1][y - 1].exist && !mapgen[x][y - 1].exist && !mapgen[x - 1][y].exist:
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x - 1, y + 1))
					disabled_points.append(Vector2i(x - 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x - 1, y))
					return true
				elif !mapgen[x][y + 1].exist && !mapgen[x + 1][y + 1].exist && !mapgen[x + 1][y - 1].exist && !mapgen[x][y - 1].exist && !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x + 1, y + 1))
					disabled_points.append(Vector2i(x + 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x - 1][y].exist && !mapgen[x - 1][y + 1].exist && !mapgen[x][y + 1].exist && !mapgen[x + 1][y + 1].exist  && !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x - 1, y + 1))
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x + 1, y + 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x - 1][y].exist && !mapgen[x - 1][y - 1].exist && !mapgen[x][y - 1].exist && !mapgen[x + 1][y - 1].exist  && !mapgen[x + 1][y].exist:
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x - 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x + 1, y - 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				else:
					return false
		1: ## ROOM2 - hallway
			## |[o][x]  
			if x == 0:
				if !mapgen[x + 1][y].exist && !disabled_points.has(Vector2i(x + 1, y)):
					disabled_points.append(Vector2i(x + 1, y))
					return true
				else:
					return false
			## [x][o]|
			elif x == size - 1:
				if !mapgen[x - 1][y].exist && !disabled_points.has(Vector2i(x - 1, y)):
					disabled_points.append(Vector2i(x - 1, y))
					return true
				else:
					return false
			## [x]
			## [o]
			## ---
			elif y == 0:
				if !mapgen[x][y + 1].exist && !disabled_points.has(Vector2i(x, y + 1)):
					disabled_points.append(Vector2i(x, y + 1))
					return true
				else:
					return false
			## ---
			## [o]
			## [x]
			elif y == size_y - 1:
				if !mapgen[x][y - 1].exist && !disabled_points.has(Vector2i(x, y - 1)):
					disabled_points.append(Vector2i(x, y - 1))
					return true
				else:
					return false
			##             [x]
			## [x][o][x]   [o]
			##             [x]
			else:
				if !mapgen[x][y + 1].exist && !mapgen[x][y - 1].exist && !disabled_points.has(Vector2i(x, y + 1)) && !disabled_points.has(Vector2i(x, y - 1)):
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x, y - 1))
					return true
				elif !mapgen[x + 1][y].exist && !mapgen[x - 1][y].exist  && !disabled_points.has(Vector2i(x + 1, y)) && !disabled_points.has(Vector2i(x - 1, y)):
					disabled_points.append(Vector2i(x + 1, y))
					disabled_points.append(Vector2i(x - 1, y))
					return true
				else:
					return false
		2: ## ROOM2C - corner
			if (x == 0 && y == 0) || (x == size - 1 && y == size_y - 1) || (x == 0 && y == size_y - 1) || (x == size - 1 && y == 0):
				return true
			## |[x]  [x]|
			## |[o]  [o]|
			## |[x]  [x]|
			elif x == 0 || x == size - 1:
				if !mapgen[x][y + 1].exist && !mapgen[x][y - 1].exist && !disabled_points.has(Vector2i(x, y + 1)) && !disabled_points.has(Vector2i(x, y - 1)): 
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x, y - 1))
					return true
				else:
					return false
			## ---------
			## [x][o][x]   [x][o][x]
			##             ---------
			elif y == 0 || y == size_y - 1:
				if !mapgen[x + 1][y].exist && !mapgen[x - 1][y].exist && !disabled_points.has(Vector2i(x - 1, y)) && !disabled_points.has(Vector2i(x + 1, y)):
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				else:
					return false
			##                   [x][x]    [x][x]    
			## [x][o]   [o][x]   [x][o]    [o][x]
			## [x][x]   [x][x]
			else:
				if !mapgen[x - 1][y].exist && !mapgen[x - 1][y - 1].exist && !mapgen[x][y - 1].exist && !disabled_points.has(Vector2i(x - 1, y - 1)) && !disabled_points.has(Vector2i(x, y - 1)) && !disabled_points.has(Vector2i(x - 1, y)):
					disabled_points.append(Vector2i(x - 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x - 1, y))
					return true
				elif !mapgen[x][y - 1].exist && !mapgen[x + 1][y - 1].exist && !mapgen[x + 1][y].exist && !disabled_points.has(Vector2i(x + 1, y - 1)) && !disabled_points.has(Vector2i(x, y - 1)) && !disabled_points.has(Vector2i(x + 1, y)):
					disabled_points.append(Vector2i(x + 1, y - 1))
					disabled_points.append(Vector2i(x, y - 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x - 1][y].exist && !mapgen[x - 1][y + 1].exist && !mapgen[x][y + 1].exist && !disabled_points.has(Vector2i(x - 1, y)) && !disabled_points.has(Vector2i(x - 1, y + 1)) && !disabled_points.has(Vector2i(x, y + 1)):
					disabled_points.append(Vector2i(x - 1, y))
					disabled_points.append(Vector2i(x - 1, y + 1))
					disabled_points.append(Vector2i(x, y + 1))
					return true
				elif !mapgen[x][y + 1].exist && !mapgen[x + 1][y + 1].exist && !mapgen[x + 1][y].exist && !disabled_points.has(Vector2i(x, y + 1)) && !disabled_points.has(Vector2i(x + 1, y + 1)) && !disabled_points.has(Vector2i(x + 1, y)):
					disabled_points.append(Vector2i(x, y + 1))
					disabled_points.append(Vector2i(x + 1, y + 1))
					disabled_points.append(Vector2i(x + 1, y))
					return true
				else:
					return false
		3: ## ROOM3 - TWay
			## |[o][x]  
			if x == 0 || y == 0 || x == size - 1 || y == size_y - 1:
				return true
			##                  [x]
			## [x][o]  [o][x]   [o]  [o]
			##                       [x]
			else:
				if !mapgen[x][y + 1].exist && !disabled_points.has(Vector2i(x, y + 1)):
					disabled_points.append(Vector2i(x, y + 1))
					return true
				elif !mapgen[x][y - 1].exist && !disabled_points.has(Vector2i(x, y - 1)):
					disabled_points.append(Vector2i(x, y - 1))
					return true
				elif !mapgen[x + 1][y].exist && !disabled_points.has(Vector2i(x + 1, y)):
					disabled_points.append(Vector2i(x + 1, y))
					return true
				elif !mapgen[x - 1][y].exist && !disabled_points.has(Vector2i(x - 1, y)):
					disabled_points.append(Vector2i(x - 1, y))
					return true
				else:
					return false
		_: ## ROOM4 and unknown types are not supported
			return false

## Main walker function, using AStarGrid2D
func walk_astar(from: Vector2, to: Vector2) -> void:
	# Initialization
	var astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, size, size_y)
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	for obstacle in disabled_points:
		astar_grid.set_point_solid(obstacle)
	var previous_map: Vector2 = from
	# Walk
	for map in astar_grid.get_point_path(from, to):
		# Get difference between previous and now position.
		# This is necessary for determining room connections
		var dir: Vector2 = map - previous_map
		previous_map = map
		mapgen[map.x][map.y].exist = true
		
		match dir:
			Vector2(1, 0):
				if mapgen[map.x - 1][map.y].exist:
					mapgen[map.x - 1][map.y].east = true
					mapgen[map.x][map.y].west = true
			Vector2(-1, 0):
				if mapgen[map.x + 1][map.y].exist:
					mapgen[map.x + 1][map.y].west = true
					mapgen[map.x][map.y].east = true
			Vector2(0, 1):
				if mapgen[map.x][map.y - 1].exist:
					mapgen[map.x][map.y - 1].north = true
					mapgen[map.x][map.y].south = true
			Vector2(0, -1):
				if mapgen[map.x][map.y + 1].exist:
					mapgen[map.x][map.y + 1].south = true
					mapgen[map.x][map.y].north = true

func place_room_positions() -> void:
	if debug_print:
		for j in range(size):
			for k in range(size_y):
				print(int(mapgen[j][k].exist))
			print()
	
	# deprecated since 6.0, copied from pre-5.0 map generators
	#var room1_amount: int = 0
	#var room2_amount: int = 0
	#var room2c_amount: int = 0
	#var room3_amount: int = 0
	#var room4_amount: int = 0
	var room2l_amount: int = 0
	var room2cl_amount: int = 0
	var room3l_amount: int = 0
	
	for l in range(size):
		for m in range(size_y):
			var north: bool
			var east: bool
			var south: bool
			var west: bool
			if mapgen[l][m].exist:
				west = mapgen[l][m].west
				east = mapgen[l][m].east
				north = mapgen[l][m].north
				south = mapgen[l][m].south
				if north && south:
					if east && west:
						#room4
						var room_angle: Array[float] = [0, 90, 180, 270]
						mapgen[l][m].room_type = RoomTypes.ROOM4
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 3)]
						#room4_amount += 1
					elif east && !west:
						#room3, pointing east
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 90
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 3) && room3l_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room3l_amount += 1
						#room3_amount += 1
					elif !east && west:
						#room3, pointing west
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 270
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 3) && room3l_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room3l_amount += 1
						#room3_amount += 1
					else:
						#vertical room2
						var room_angle: Array[float] = [0, 180]
						mapgen[l][m].room_type = RoomTypes.ROOM2
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 1) && room2l_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room2l_amount += 1
						#room2_amount += 1
				elif east && west:
					if north && !south:
						#room3, pointing north
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 0
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 3) && room3l_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room3l_amount += 1
						#room3_amount += 1
					elif !north && south:
					#room3, pointing south
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 180
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 3) && room3l_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room3l_amount += 1
						#room3_amount += 1
					else:
					#horizontal room2
						var room_angle: Array[float] = [90, 270]
						mapgen[l][m].room_type = RoomTypes.ROOM2
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 1) && room2l_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room2l_amount += 1
						#room2_amount += 1
				elif north:
					if east:
					#room2c, north-east
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 0
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 2) && room2cl_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room2cl_amount += 1
						#room2c_amount += 1
					elif west:
					#room2c, north-west
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 270
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 2) && room2cl_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room2cl_amount += 1
						#room2c_amount += 1
					else:
					#room1, north
						mapgen[l][m].room_type = RoomTypes.ROOM1
						mapgen[l][m].angle = 0
						#room1_amount += 1
				elif south:
					if east:
					#room2c, south-east
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 90
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 2) && room2cl_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room2cl_amount += 1
						#room2c_amount += 1
					elif west:
					#room2c, south-west
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 180
						if large_rooms:
							var zone: int = m / size
							if check_room_dimensions(l, m, 2) && room2cl_amount < size / 6 * (zones_amount + 1):
								mapgen[l][m].large = true
								room2cl_amount += 1
						#room2c_amount += 1
					else:
					#room1, south
						mapgen[l][m].room_type = RoomTypes.ROOM1
						mapgen[l][m].angle = 180
						#room1_amount += 1
				elif east:
					#room1, east
					mapgen[l][m].room_type = RoomTypes.ROOM1
					mapgen[l][m].angle = 90
					#room1_amount += 1
				else:
					#room1, west
					mapgen[l][m].room_type = RoomTypes.ROOM1
					mapgen[l][m].angle = 270
					#room1_amount += 1
	spawn_rooms()

## Spawns room prefab on the grid
func spawn_rooms() -> void:
	# Checks the zone
	var zone_counter: int = 0
	var selected_room: PackedScene
	var room1_count: Array[int] = [0]
	var room2_count: Array[int] = [0]
	var room2c_count: Array[int] = [0]
	var room3_count: Array[int] = [0]
	var room4_count: Array[int] = [0]
	var room1l_count: Array[int] = [0]
	var room2l_count: Array[int] = [0]
	var room2cl_count: Array[int] = [0]
	var room3l_count: Array[int] = [0]
	var counter: float = 0.0
	var prev_counter: float = 0.0
	if zones_amount > 0:
		for i in range(zones_amount):
			room1_count.append(0)
			room2_count.append(0)
			room2c_count.append(0)
			room3_count.append(0)
			room4_count.append(0)
			room1l_count.append(0)
			room2l_count.append(0)
			room2cl_count.append(0)
			room3l_count.append(0)
	#spawn a room
	for n in range(size):
		for o in range(size_y):
			if o >= size_y / (zones_amount + 1) * (zone_counter + 1):
				zone_counter += 1
			var room: StaticBody3D
			match mapgen[n][o].room_type:
				RoomTypes.ROOM1:
					if mapgen[n][o].large && large_rooms && rooms[zone_counter].endrooms_single_large.size() > 0 && room1l_count[zone_counter] < rooms[zone_counter].endrooms_single_large.size():
						selected_room = rooms[zone_counter].endrooms_single_large[room1l_count[zone_counter]].prefab
						room1l_count[zone_counter] += 1
					else:
						if rooms[zone_counter].endrooms_single_large.size() > 0 && !large_rooms && room1l_count[zone_counter] < rooms[zone_counter].endrooms_single_large.size():
							selected_room = rooms[zone_counter].endrooms_single_large[room1l_count[zone_counter]].prefab
						elif (room1_count[zone_counter] >= rooms[zone_counter].endrooms_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_counter].endrooms.size()):
								all_spawn_chances.append(rooms[zone_counter].endrooms[j].spawn_chance)
								spawn_chances += rooms[zone_counter].endrooms[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_counter].endrooms[i].prefab
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_counter].endrooms_single[room1_count[zone_counter]].prefab
							room1_count[zone_counter] += 1
					
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM2:
					if mapgen[n][o].large && large_rooms && rooms[zone_counter].hallways_single_large.size() > 0 && room2l_count[zone_counter] < rooms[zone_counter].hallways_single_large.size():
						selected_room = rooms[zone_counter].hallways_single_large[room2l_count[zone_counter]].prefab
						room2l_count[zone_counter] += 1
					else:
						if rooms[zone_counter].hallways_single_large.size() > 0 && !large_rooms && room2l_count[zone_counter] < rooms[zone_counter].hallways_single_large.size():
							selected_room = rooms[zone_counter].hallways_single_large[room2l_count[zone_counter]].prefab
						elif (room2_count[zone_counter] >= rooms[zone_counter].hallways_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_counter].hallways.size()):
								all_spawn_chances.append(rooms[zone_counter].hallways[j].spawn_chance)
								spawn_chances += rooms[zone_counter].hallways[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_counter].hallways[i].prefab
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_counter].hallways_single[room2_count[zone_counter]].prefab
							room2_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM2C:
					if mapgen[n][o].large && large_rooms && rooms[zone_counter].corners_single_large.size() > 0 && room2cl_count[zone_counter] < rooms[zone_counter].corners_single_large.size():
						selected_room = rooms[zone_counter].corners_single_large[room2cl_count[zone_counter]].prefab
						room2cl_count[zone_counter] += 1
					else:
						if rooms[zone_counter].corners_single_large.size() > 0 && !large_rooms && room2cl_count[zone_counter] < rooms[zone_counter].corners_single_large.size():
							selected_room = rooms[zone_counter].corners_single_large[room2cl_count[zone_counter]].prefab
						elif (room2c_count[zone_counter] >= rooms[zone_counter].corners_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_counter].corners.size()):
								all_spawn_chances.append(rooms[zone_counter].corners[j].spawn_chance)
								spawn_chances += rooms[zone_counter].corners[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_counter].corners[i].prefab
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_counter].corners_single[room2c_count[zone_counter]].prefab
							room2c_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM3:
					if mapgen[n][o].large && large_rooms && rooms[zone_counter].trooms_single_large.size() > 0 && room3l_count[zone_counter] < rooms[zone_counter].trooms_single_large.size():
						selected_room = rooms[zone_counter].trooms_single_large[room3l_count[zone_counter]].prefab
						room3l_count[zone_counter] += 1
					else:
						if rooms[zone_counter].trooms_single_large.size() > 0 && !large_rooms && room3l_count[zone_counter] < rooms[zone_counter].trooms_single_large.size():
							selected_room = rooms[zone_counter].trooms_single_large[room3l_count[zone_counter]].prefab
						elif (room3_count[zone_counter] >= rooms[zone_counter].trooms_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_counter].trooms.size()):
								all_spawn_chances.append(rooms[zone_counter].trooms[j].spawn_chance)
								spawn_chances += rooms[zone_counter].trooms[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_counter].trooms[i].prefab
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_counter].trooms_single[room3_count[zone_counter]].prefab
							room3_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM4:
					if (room4_count[zone_counter] >= rooms[zone_counter].crossrooms_single.size()):
						var all_spawn_chances: Array[float] = []
						var spawn_chances: float = 0
						for j in range(rooms[zone_counter].crossrooms.size()):
							all_spawn_chances.append(rooms[zone_counter].crossrooms[j].spawn_chance)
							spawn_chances += rooms[zone_counter].crossrooms[j].spawn_chance
						var random_room: float = rng.randf_range(0.0, spawn_chances)
						for i in range(all_spawn_chances.size()):
							counter += all_spawn_chances[i]
							if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
								selected_room = rooms[zone_counter].crossrooms[i].prefab
								break
							prev_counter = counter
						all_spawn_chances.clear()
						counter = 0
						prev_counter = 0
					else:
						selected_room = rooms[zone_counter].crossrooms_single[room4_count[zone_counter]].prefab
					room4_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
		zone_counter = 0
	if enable_door_generation:
		spawn_doors()
	generated.emit()
## Spawn doors
func spawn_doors():
	# Checks the zone
	var zone_counter: int = 0
	var startup_node: Node = Node.new()
	startup_node.name = "DoorFrames"
	add_child(startup_node)
	for i in range(size):
		for j in range(size_y):
			if j >= size_y / (zones_amount + 1) * (zone_counter + 1):
				zone_counter += 1
			if rooms[zone_counter].door_frames.size() > 0:
				var available_frames: Array[PackedScene] = rooms[zone_counter].door_frames
				if mapgen[i][j].east:
					var door: Node3D = available_frames[rng.randi_range(0, available_frames.size() - 1)].instantiate()
					door.position = global_position + Vector3(i * grid_size + grid_size / 2, 0, j * grid_size)
					door.rotation_degrees = Vector3(0, 90, 0)
					startup_node.add_child(door, true)
				if mapgen[i][j].north:
					var door: Node3D = available_frames[rng.randi_range(0, available_frames.size() - 1)].instantiate()
					door.position = global_position + Vector3(i * grid_size, 0, j * grid_size + grid_size / 2)
					door.rotation_degrees = Vector3(0, 0, 0)
					startup_node.add_child(door, true)
		zone_counter = 0
## Clears the map generation
func clear():
	disabled_points.clear()
	mapgen.clear()
	for node in get_children():
		node.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
