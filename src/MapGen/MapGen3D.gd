@icon("res://MapGen/icons/MapGenNode3D.svg")
extends Node3D
class_name FacilityGenerator3D

signal generated

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

## Works only if there are large endrooms, to prevent endless loop if cannot spawn
const NUMBER_OF_TRIES_TO_SPAWN: int = 4
## For performance reasons. Correct the code to increase the limit
const MAX_ROOMS_SPAWN: int = 256

@export var rng_seed: int = -1
## Rooms that will be used
@export var rooms: Array[MapGenZone]
## Zone size
@export_range(8, 256, 2) var zone_size: int = 8
## Amount of zones by X coordinate
@export_range(0, 3) var map_size_x: int = 0
## Amount of zones by Y coordinate
@export_range(0, 3) var map_size_y: int = 0
## Room in grid size
@export var grid_size: float = 20.48
## Large rooms support
@export var large_rooms: bool = false
## How much the map will be filled with rooms
@export_range(0.25, 1) var room_amount: float = 0.75
## Sets the door generation. Not recommended to disable, if your map uses SCP:SL 14.0-like door frames!
@export var enable_door_generation: bool = true
## Better zone generation.
## Sometimes, the generation will return "dull" path(e.g where there are only 3 ways to go)
## This fixes these generations, at a little cost of generation time
@export var better_zone_generation: bool = true
# Deprecated since mapgen v8
# How much the better map generator should wait, until it finds optimal path.
# Lower value can lead to fewer amount of rooms, while higher can hang the whole game.
#@export var better_zone_generation_waiter: int = 1
## How many endrooms should spawn map generator
## /!\ WARNING! Higher value may hang the game.
@export var better_zone_generation_min_amount: int = 5
## Prints map seed
@export var debug_print: bool = false

var mapgen: Array[Array] = []
## Cells, where a room will never spawn due to large room overriden
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
	var resource: MapGenRoom
	var room_name: String

var size_x: int
var size_y: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

## Prepares room generation
func prepare_generation() -> void:
	if debug_print:
		print("Preparing generation...")
	size_x = zone_size * (map_size_x + 1)
	size_y = zone_size * (map_size_y + 1)
	if rng_seed != -1:
		rng.seed = rng_seed
	# Fill mapgen with zeros
	for g in range(size_x):
		mapgen.append([])
		for h in range(size_y):
			mapgen[g].append(Room.new())
			mapgen[g][h].exist = false
			mapgen[g][h].north = false
			mapgen[g][h].south = false
			mapgen[g][h].east = false
			mapgen[g][h].west = false
			mapgen[g][h].room_type = RoomTypes.EMPTY
			mapgen[g][h].angle = -1
			mapgen[g][h].large = false
	generate_zone_astar()

## Main function, that generate the zones. Rewritten in 7.0
func generate_zone_astar() -> void:
	if debug_print:
		print("Generating the map...")
	# Zone counter. Used for determining a center of the map.
	var zone_counter: Vector2i = Vector2i.ZERO
	# Zone index. Used for iterating zone resources.
	var zone_index: int = 0
	# Zone index for Y coordinate.
	var zone_index_default: int = 0
	# Determines, if the generation is too large to stop it.
	# You can change the limit in MAX_ROOM_SPAWN const.
	var all_rooms_count: int = 0
	# Zone center for the first quadrant.
	var zone_center: float = zone_size / 2
	for i in range(map_size_x + 1):
		zone_counter.x = i
		for j in range(map_size_y + 1):
			# Large room amount
			var large_room_amount: int = zone_size / 6
			zone_counter.y = j
			zone_index += j
			var number_of_rooms: int = zone_size * room_amount
			all_rooms_count += number_of_rooms
			if all_rooms_count > MAX_ROOMS_SPAWN:
				printerr("The limit of " + str(MAX_ROOMS_SPAWN) + """ rooms for all zones reached. Stopping the program... 
					If you want to increase the limit, set MAX_ROOM_SPAWN constant to higher value, althrough it is not recommended.""")
				return
			# to deal with zero-sized zone_counter, there is a simple formula - if is not odd - 
			# add value to be not null
			var tmp_x: int = 0
			var tmp_y: int = 0
			#if (zone_counter.x % 2 == 1):
				#tmp_x = (zone_counter.x + 2 * zone_counter.x)
			#else: # add one to be an odd number
				#tmp_x = (zone_counter.x + 1 + 2 * zone_counter.x)
			#if (zone_counter.y % 2 == 1):
				#tmp_y = (zone_counter.y + 2 * zone_counter.y)
			#else: # add one to be an odd number
				#tmp_y = (zone_counter.y + 1 + 2 * zone_counter.y)
			#var zone_center: Vector2 = Vector2(float(size_x) * (float(tmp_x) / float((map_size_x + 1) * 2)), float(size_y) * (float(tmp_y) / float((map_size_y + 1) * 2)))
			var current_zone_center: Vector2 = Vector2(zone_center + (zone_size * zone_counter.x), zone_center + (zone_size * zone_counter.y))
			mapgen[roundi(current_zone_center.x)][roundi(current_zone_center.y)].exist = true
			if number_of_rooms > (zone_size - 1) * 4 - 4 - large_room_amount * 6:
				printerr("Too many rooms, map won't spawn")
				return
			elif number_of_rooms < 1:
				printerr("Too few rooms, map won't spawn")
				return
			# Available room position (for AStar walk)
			var available_room_position: Array[Vector2] = [Vector2(size_x / (map_size_x + 1) * zone_counter.x, size_x / (map_size_x + 1) * (zone_counter.x + 1) - 1),Vector2(size_y / (map_size_y + 1) * zone_counter.y, size_y / (map_size_y + 1) * (zone_counter.y + 1) - 1)]
			# Random room position. If large rooms enabled, also used for large room coordinates
			var random_room: Vector2
			## Reworked large rooms module
			if large_rooms && rooms[zone_index].endrooms_single_large.size() > 0:
				for k in range(large_room_amount):
					for l in range(NUMBER_OF_TRIES_TO_SPAWN):
						random_room = Vector2(rng.randi_range(available_room_position[0].x, available_room_position[0].y), rng.randi_range(available_room_position[1].x, available_room_position[1].y))
						if check_room_dimensions(random_room.x, random_room.y, 0):
							walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), random_room)
							mapgen[random_room.x][random_room.y].large = true
							break
			## This "waiter" is for not stalling the map gen
			var waiter: int = 0
			## Walk before need-to-spawn rooms runs out
			while number_of_rooms > 0:
				random_room = Vector2(rng.randi_range(available_room_position[0].x, available_room_position[0].y), rng.randi_range(available_room_position[1].x, available_room_position[1].y))
				#if better_zone_generation && mapgen[random_room.x][random_room.y].exist && waiter < better_zone_generation_waiter:
					#waiter += 1
					#continue
				walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), random_room)
				waiter = 0
				number_of_rooms -= 1
				
			## Connect two zones
			if zone_counter.x < map_size_x:
				#var tmp_x2: int
				#if (zone_counter.x % 2 == 1):
					#tmp_x2 = (zone_counter.x + 2 + 2 * zone_counter.x)
				#else: # add one to be an odd number
					#tmp_x2 = (zone_counter.x + 3 + 2 * zone_counter.x)
				#var zone_center_x: int = float(size_x) * (float(tmp_x2) / float((map_size_x + 1) * 2))
				var zone_center_x: int = roundi(zone_center + (zone_size * (zone_counter.x + 1)))
				walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), Vector2(zone_center_x, roundi(current_zone_center.y)))
			if zone_counter.y < map_size_y:
				#var tmp_y2: int
				#if (zone_counter.x % 2 == 1):
					#tmp_y2 = (zone_counter.y + 2 + 2 * zone_counter.y)
				#else: # add one to be an odd number
					#tmp_y2 = (zone_counter.y + 3 + 2 * zone_counter.y)
				#var zone_center_y: int = float(size_y) * (float(tmp_y2) / float((map_size_y + 1) * 2))
				var zone_center_y: int = roundi(zone_center + (zone_size * (zone_counter.y + 1)))
				walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), Vector2(roundi(current_zone_center.x), zone_center_y))
		zone_index_default += map_size_y
		zone_counter.y = 0
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
			elif x == size_x - 1 && y == size_y - 1:
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
			elif x == size_x - 1 && y == 0:
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
			elif x == size_x - 1:
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
			elif x == size_x - 1:
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
			if (x == 0 && y == 0) || (x == size_x - 1 && y == size_y - 1) || (x == 0 && y == size_y - 1) || (x == size_x - 1 && y == 0):
				return true
			## |[x]  [x]|
			## |[o]  [o]|
			## |[x]  [x]|
			elif x == 0 || x == size_x - 1:
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
			if x == 0 || y == 0 || x == size_x - 1 || y == size_y - 1:
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
	var astar_grid: AStarGrid2D = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, size_x, size_y)
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
		print("Map generated:")
		for j in range(size_x):
			var debug_string: String = ""
			for k in range(size_y):
				debug_string += str(int(mapgen[j][k].exist))
			print(debug_string)
		print("Connecting rooms...")
	# Regular rooms amount (needed for better generation)
	var room1_amount: Array[int] = []
	var room2_amount: Array[int] = []
	var room2c_amount: Array[int] = []
	var room3_amount: Array[int] = []
	var room4_amount: Array[int] = []
	# Large rooms amount
	var room2l_amount: Array[int] = []
	var room2cl_amount: Array[int] = []
	var room3l_amount: Array[int] = []
	
	var zone_counter: Vector2i = Vector2i.ZERO
	var room_index: int = 0
	var room_index_default: int = 0
	# Initialize values
	room1_amount.append(0)
	room2_amount.append(0)
	room2c_amount.append(0)
	room3_amount.append(0)
	room4_amount.append(0)
	
	room2l_amount.append(0)
	room2cl_amount.append(0)
	room3l_amount.append(0)
	for l in range(size_x):
		#append zone horizontal
		if l >= size_x / (map_size_x + 1) * (zone_counter.x + 1):
			zone_counter.x += 1
			room1_amount.append(0)
			room2_amount.append(0)
			room2c_amount.append(0)
			room3_amount.append(0)
			room4_amount.append(0)
			
			room2l_amount.append(0)
			room2cl_amount.append(0)
			room3l_amount.append(0)
			room_index_default += 1
		for m in range(size_y):
			#append zone vertical
			if m >= size_y / (map_size_y + 1) * (zone_counter.y + 1):
				zone_counter.y += 1
				room1_amount.append(0)
				room2_amount.append(0)
				room2c_amount.append(0)
				room3_amount.append(0)
				room4_amount.append(0)
				
				room2l_amount.append(0)
				room2cl_amount.append(0)
				room3l_amount.append(0)
				room_index += 1
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
						room4_amount[room_index] += 1
					elif east && !west:
						#room3, pointing east
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 90
						if large_rooms:
							if check_room_dimensions(l, m, 3) && room3l_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room3l_amount[room_index] += 1
						room3_amount[room_index] += 1
					elif !east && west:
						#room3, pointing west
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 270
						if large_rooms:
							if check_room_dimensions(l, m, 3) && room3l_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room3l_amount[room_index] += 1
						room3_amount[room_index] += 1
					else:
						#vertical room2
						var room_angle: Array[float] = [0, 180]
						mapgen[l][m].room_type = RoomTypes.ROOM2
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						if large_rooms:
							if check_room_dimensions(l, m, 1) && room2l_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room2l_amount[room_index] += 1
						room2_amount[room_index] += 1
				elif east && west:
					if north && !south:
						#room3, pointing north
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 0
						if large_rooms:
							if check_room_dimensions(l, m, 3) && room3l_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room3l_amount[room_index] += 1
						room3_amount[room_index] += 1
					elif !north && south:
					#room3, pointing south
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 180
						if large_rooms:
							if check_room_dimensions(l, m, 3) && room3l_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room3l_amount[room_index] += 1
						room3_amount[room_index] += 1
					else:
					#horizontal room2
						var room_angle: Array[float] = [90, 270]
						mapgen[l][m].room_type = RoomTypes.ROOM2
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						if large_rooms:
							if check_room_dimensions(l, m, 1) && room2l_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room2l_amount[room_index] += 1
						room2_amount[room_index] += 1
				elif north:
					if east:
					#room2c, north-east
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 0
						if large_rooms:
							if check_room_dimensions(l, m, 2) && room2cl_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room2cl_amount[room_index] += 1
						room2c_amount[room_index] += 1
					elif west:
					#room2c, north-west
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 270
						if large_rooms:
							if check_room_dimensions(l, m, 2) && room2cl_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room2cl_amount[room_index] += 1
						room2c_amount[room_index] += 1
					else:
					#room1, north
						mapgen[l][m].room_type = RoomTypes.ROOM1
						mapgen[l][m].angle = 0
						room1_amount[room_index] += 1
				elif south:
					if east:
					#room2c, south-east
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 90
						if large_rooms:
							if check_room_dimensions(l, m, 2) && room2cl_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room2cl_amount[room_index] += 1
						room2c_amount[room_index] += 1
					elif west:
					#room2c, south-west
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 180
						if large_rooms:
							if check_room_dimensions(l, m, 2) && room2cl_amount[room_index] < zone_size / 6:
								mapgen[l][m].large = true
								room2cl_amount[room_index] += 1
						room2c_amount[room_index] += 1
					else:
					#room1, south
						mapgen[l][m].room_type = RoomTypes.ROOM1
						mapgen[l][m].angle = 180
						room1_amount[room_index] += 1
				elif east:
					#room1, east
					mapgen[l][m].room_type = RoomTypes.ROOM1
					mapgen[l][m].angle = 90
					room1_amount[room_index] += 1
				else:
					#room1, west
					mapgen[l][m].room_type = RoomTypes.ROOM1
					mapgen[l][m].angle = 270
					room1_amount[room_index] += 1
		zone_counter.y = 0
		room_index = room_index_default
	if better_zone_generation:
		for j in range(room_index + 1):
			if room1_amount[j] < better_zone_generation_min_amount:
				clear()
				rng_seed = -1
				rng.randomize()
				prepare_generation()
				return
	spawn_rooms()

## Spawns room prefab on the grid
func spawn_rooms() -> void:
	if debug_print:
		print("Spawning rooms...")
	# Checks the zone
	var zone_counter: Vector2i = Vector2i.ZERO
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
	var zone_index_default: int = 0
	var zone_index: int = 0
	#if zones_amount > 0:
		#for i in range(zones_amount):
			#room1_count.append(0)
			#room2_count.append(0)
			#room2c_count.append(0)
			#room3_count.append(0)
			#room4_count.append(0)
			#room1l_count.append(0)
			#room2l_count.append(0)
			#room2cl_count.append(0)
			#room3l_count.append(0)
	#spawn a room
	for n in range(size_x):
		if n >= size_x / (map_size_x + 1) * (zone_counter.x + 1):
			zone_counter.x += 1
			room1_count.append(0)
			room2_count.append(0)
			room2c_count.append(0)
			room3_count.append(0)
			room4_count.append(0)
			room1l_count.append(0)
			room2l_count.append(0)
			room2cl_count.append(0)
			room3l_count.append(0)
			# we need to add map_size by Y, because the Y grid will be full in previous X:
			# e.g.:
			# 0|2
			# -=-
			# 1|3
			zone_index_default += map_size_y + 1
		for o in range(size_y):
			if o >= size_y / (map_size_y + 1) * (zone_counter.y + 1):
				zone_counter.y += 1
				room1_count.append(0)
				room2_count.append(0)
				room2c_count.append(0)
				room3_count.append(0)
				room4_count.append(0)
				room1l_count.append(0)
				room2l_count.append(0)
				room2cl_count.append(0)
				room3l_count.append(0)
				zone_index += 1
			var room: StaticBody3D
			match mapgen[n][o].room_type:
				RoomTypes.ROOM1:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].endrooms_single_large.size() > 0 && room1l_count[zone_index] < rooms[zone_index].endrooms_single_large.size():
						selected_room = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]].prefab
						mapgen[n][o].resource = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]]
						room1l_count[zone_index] += 1
					else:
						if rooms[zone_index].endrooms_single_large.size() > 0 && !large_rooms && room1l_count[zone_index] < rooms[zone_index].endrooms_single_large.size():
							selected_room = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]]
							room1l_count[zone_index] += 1
						elif (room1_count[zone_index] >= rooms[zone_index].endrooms_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_index].endrooms.size()):
								all_spawn_chances.append(rooms[zone_index].endrooms[j].spawn_chance)
								spawn_chances += rooms[zone_index].endrooms[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_index].endrooms[i].prefab
									mapgen[n][o].resource = rooms[zone_index].endrooms[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_index].endrooms_single[room1_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].endrooms_single[room1_count[zone_index]]
							room1_count[zone_index] += 1
					
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
					add_child(room, true)
					mapgen[n][o].room_name = room.name
				RoomTypes.ROOM2:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].hallways_single_large.size() > 0 && room2l_count[zone_index] < rooms[zone_index].hallways_single_large.size():
						selected_room = rooms[zone_index].hallways_single_large[room2l_count[zone_index]].prefab
						mapgen[n][o].resource = rooms[zone_index].hallways_single_large[room2l_count[zone_index]]
						room2l_count[zone_index] += 1
					else:
						if rooms[zone_index].hallways_single_large.size() > 0 && !large_rooms && room2l_count[zone_index] < rooms[zone_index].hallways_single_large.size():
							selected_room = rooms[zone_index].hallways_single_large[room2l_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].hallways_single_large[room2l_count[zone_index]]
							room2l_count[zone_index] += 1
						elif (room2_count[zone_index] >= rooms[zone_index].hallways_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_index].hallways.size()):
								all_spawn_chances.append(rooms[zone_index].hallways[j].spawn_chance)
								spawn_chances += rooms[zone_index].hallways[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_index].hallways[i].prefab
									mapgen[n][o].resource = rooms[zone_index].hallways[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_index].hallways_single[room2_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].hallways_single[room2_count[zone_index]]
							room2_count[zone_index] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
					add_child(room, true)
					mapgen[n][o].room_name = room.name
				RoomTypes.ROOM2C:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].corners_single_large.size() > 0 && room2cl_count[zone_index] < rooms[zone_index].corners_single_large.size():
						selected_room = rooms[zone_index].corners_single_large[room2cl_count[zone_index]].prefab
						mapgen[n][o].resource = rooms[zone_index].corners_single_large[room2cl_count[zone_index]]
						room2cl_count[zone_index] += 1
					else:
						if rooms[zone_index].corners_single_large.size() > 0 && !large_rooms && room2cl_count[zone_index] < rooms[zone_index].corners_single_large.size():
							selected_room = rooms[zone_index].corners_single_large[room2cl_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].corners_single_large[room2cl_count[zone_index]]
							room2cl_count[zone_index] += 1
						elif (room2c_count[zone_index] >= rooms[zone_index].corners_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_index].corners.size()):
								all_spawn_chances.append(rooms[zone_index].corners[j].spawn_chance)
								spawn_chances += rooms[zone_index].corners[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_index].corners[i].prefab
									mapgen[n][o].resource = rooms[zone_index].corners[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_index].corners_single[room2c_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].corners_single[room2c_count[zone_index]]
							room2c_count[zone_index] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
					add_child(room, true)
					mapgen[n][o].room_name = room.name
				RoomTypes.ROOM3:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].trooms_single_large.size() > 0 && room3l_count[zone_index] < rooms[zone_index].trooms_single_large.size():
						selected_room = rooms[zone_index].trooms_single_large[room3l_count[zone_index]].prefab
						mapgen[n][o].resource = rooms[zone_index].trooms_single_large[room3l_count[zone_index]]
						room3l_count[zone_index] += 1
					else:
						if rooms[zone_index].trooms_single_large.size() > 0 && !large_rooms && room3l_count[zone_index] < rooms[zone_index].trooms_single_large.size():
							selected_room = rooms[zone_index].trooms_single_large[room3l_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].trooms_single_large[room3l_count[zone_index]]
							room3l_count[zone_index] += 1
						elif (room3_count[zone_index] >= rooms[zone_index].trooms_single.size()):
							var all_spawn_chances: Array[float] = []
							var spawn_chances: float = 0
							for j in range(rooms[zone_index].trooms.size()):
								all_spawn_chances.append(rooms[zone_index].trooms[j].spawn_chance)
								spawn_chances += rooms[zone_index].trooms[j].spawn_chance
							var random_room: float = rng.randf_range(0.0, spawn_chances)
							for i in range(all_spawn_chances.size()):
								counter += all_spawn_chances[i]
								if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
									selected_room = rooms[zone_index].trooms[i].prefab
									mapgen[n][o].resource = rooms[zone_index].trooms[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							selected_room = rooms[zone_index].trooms_single[room3_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].trooms_single[room3_count[zone_index]]
							room3_count[zone_index] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
					add_child(room, true)
					mapgen[n][o].room_name = room.name
				RoomTypes.ROOM4:
					if (room4_count[zone_index] >= rooms[zone_index].crossrooms_single.size()):
						var all_spawn_chances: Array[float] = []
						var spawn_chances: float = 0
						for j in range(rooms[zone_index].crossrooms.size()):
							all_spawn_chances.append(rooms[zone_index].crossrooms[j].spawn_chance)
							spawn_chances += rooms[zone_index].crossrooms[j].spawn_chance
						var random_room: float = rng.randf_range(0.0, spawn_chances)
						for i in range(all_spawn_chances.size()):
							counter += all_spawn_chances[i]
							if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
								selected_room = rooms[zone_index].crossrooms[i].prefab
								mapgen[n][o].resource = rooms[zone_index].crossrooms[i]
								break
							prev_counter = counter
						all_spawn_chances.clear()
						counter = 0
						prev_counter = 0
					else:
						selected_room = rooms[zone_index].crossrooms_single[room4_count[zone_index]].prefab
						mapgen[n][o].resource = rooms[zone_index].crossrooms_single[room4_count[zone_index]]
						room4_count[zone_index] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
					add_child(room, true)
					mapgen[n][o].room_name = room.name
		zone_counter.y = 0
		zone_index = zone_index_default
	if enable_door_generation:
		spawn_doors()
	generated.emit()
## Spawn doors
func spawn_doors():
	if debug_print:
		print("Spawning doors...")
	# Checks the zone
	var zone_counter: Vector2i = Vector2i.ZERO
	var zone_index: int = 0
	var zone_index_default: int = 0
	var startup_node: Node = Node.new()
	startup_node.name = "DoorFrames"
	add_child(startup_node)
	for i in range(size_x):
		if i >= size_x / (map_size_x + 1) * (zone_counter.x + 1):
			zone_counter.x += 1
			zone_index_default += map_size_y + 1
		for j in range(size_y):
			if j >= size_y / (map_size_y + 1) * (zone_counter.y + 1):
				zone_counter.y += 1
				zone_index += 1
			if rooms[zone_index].door_frames.size() > 0:
				var available_frames: Array[PackedScene] = rooms[zone_index].door_frames
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
		zone_index = zone_index_default
		zone_counter.y = 0
## Clears the map generation
func clear():
	print("Clearing the map...")
	disabled_points.clear()
	mapgen.clear()
	for node in get_children():
		node.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
