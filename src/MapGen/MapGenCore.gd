@icon("res://MapGen/icons/MapGenNode.svg")
extends Node
class_name MapGenCore

var rng: RandomNumberGenerator

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

## Works only if there are large endrooms, to prevent endless loop if cannot spawn
const NUMBER_OF_TRIES_TO_SPAWN: int = 4
## For performance reasons. Correct the code to increase the limit
const MAX_ROOMS_SPAWN: int = 512

@export var rng_seed: int = -1
## Rooms that will be used
@export var rooms: Array[MapGenZone]
## Zone size (values before 8 NOT recommended, may lead to unexpected behavior)
@export_range(8, 256, 2) var zone_size: int = 8
## Amount of zones by X coordinate
@export_range(0, 3) var map_size_x: int = 0
## Amount of zones by Y coordinate
@export_range(0, 3) var map_size_y: int = 0
## Room in grid size
@export var grid_size: float = 64
## Large rooms support
@export var large_rooms: bool = false
## How much the map will be filled with rooms
@export_range(0.25, 1) var room_amount: float = 0.75
# Sets the door generation. Not recommended to disable, if your map uses SCP:SL 14.0-like door frames!
#@export var enable_door_generation: bool = true
## Better zone generation.
## Sometimes, the generation will return "dull" path(e.g where there are only 3 ways to go)
## This fixes these generations, at a little cost of generation time
@export var better_zone_generation: bool = true
## How many additional rooms should spawn map generator
## /!\ WARNING! Higher value may hang the game.
@export_range(0, 5) var better_zone_generation_min_amount: int = 4
## Enable checkpoint rooms.
## /!\ WARNING! The checkpoint room behaves differently, than SCP-CB checkpoints,
## the "checkpoint" have 2 rooms, not one (as in SCP-CB).
@export var checkpoints_enabled: bool = false
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
	var checkpoint: bool

var size_x: int
var size_y: int

var endroom_amount: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng = get_parent().rng


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_generation() -> Array[Array]:
	clear()
	prepare_generation()
	# Determines, if the generation is too large to stop it.
	# You can change the limit in MAX_ROOM_SPAWN const.
	var all_rooms_count: int = size_x * size_y * room_amount
	if all_rooms_count > MAX_ROOMS_SPAWN:
		printerr("The limit of " + str(MAX_ROOMS_SPAWN) + " rooms for all zones reached. Stopping the program...")
		printerr("If you want to increase the limit, set MAX_ROOM_SPAWN constant to higher value, althrough it is not recommended.")
	else:
		generate_zone_astar()
		place_room_positions()
	return mapgen

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
			mapgen[g][h].checkpoint = false

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
	
	# Zone center for the first quadrant.
	var zone_center: float = zone_size / 2
	for i in range(map_size_x + 1):
		zone_counter.x = i
		for j in range(map_size_y + 1):
			# Large room amount (when checkpoints enabled, there are fewer rooms)
			var large_room_amount: int = zone_size / 6 if !checkpoints_enabled else (zone_size - 2) / 6
			zone_counter.y = j
			zone_index += j
			var number_of_rooms: int = zone_size * room_amount
			# to deal with zero-sized zone_counter, there is a simple formula - if is not odd - 
			# add value to be not null
			var tmp_x: int = 0
			var tmp_y: int = 0
			
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
			## Walk before need-to-spawn rooms runs out
			while number_of_rooms > 0:
				if checkpoints_enabled:
					## If checkpoints enabled, disable non-checkpoint rooms in generic hallway generation
					random_room = Vector2(rng.randi_range(available_room_position[0].x + 1, available_room_position[0].y - 1), rng.randi_range(available_room_position[1].x + 1, available_room_position[1].y - 1))
				else: ## Do as it was in 7.x, except reverted old better zone generation
					random_room = Vector2(rng.randi_range(available_room_position[0].x, available_room_position[0].y), rng.randi_range(available_room_position[1].x, available_room_position[1].y))
				if better_zone_generation && mapgen[random_room.x][random_room.y].exist && endroom_amount < better_zone_generation_min_amount:
					continue
				walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), random_room)
				number_of_rooms -= 1
				
			## Connect two zones
			if zone_counter.x < map_size_x:
				var zone_center_x: int = roundi(zone_center + (zone_size * (zone_counter.x + 1)))
				walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), Vector2(zone_center_x, roundi(current_zone_center.y)))
			if zone_counter.y < map_size_y:
				var zone_center_y: int = roundi(zone_center + (zone_size * (zone_counter.y + 1)))
				walk_astar(Vector2(roundi(current_zone_center.x), roundi(current_zone_center.y)), Vector2(roundi(current_zone_center.x), zone_center_y))
		zone_index_default += map_size_y
		zone_counter.y = 0

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
	endroom_amount += 1
## Places information about rooms
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
					else: #room2
						if m < size_y - 1 && m > 0:
							#upper checkpoint room2
							if m == size_y / (map_size_y + 1) * zone_counter.y && mapgen[l][m-1].exist && checkpoints_enabled:
								mapgen[l][m].checkpoint = true
								mapgen[l][m].angle = 180
							#lower checkpoint room2
							elif m == size_y / (map_size_y + 1) * (zone_counter.y + 1) - 1 && mapgen[l][m+1].exist && checkpoints_enabled:
								mapgen[l][m].checkpoint = true
								mapgen[l][m].angle = 0
							else: #generic vertical room2
								var room_angle: Array[float] = [0, 180]
								mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						else: #generic vertical room2
							var room_angle: Array[float] = [0, 180]
							mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						mapgen[l][m].room_type = RoomTypes.ROOM2
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
					else:#room2
						if l < size_x - 1 && l > 0:
							#right checkpoint room2
							if l == size_x / (map_size_x + 1) * zone_counter.x && mapgen[l-1][m].exist:
								mapgen[l][m].checkpoint = true
								mapgen[l][m].angle = 270
							#left checkpoint room2
							elif l == size_x / (map_size_x + 1) * (zone_counter.x + 1) - 1 && mapgen[l+1][m].exist:
								mapgen[l][m].checkpoint = true
								mapgen[l][m].angle = 90
							else: #generic horizontal room2
								var room_angle: Array[float] = [90, 270]
								mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						else: #generic horizontal room2
							var room_angle: Array[float] = [90, 270]
							mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						
						mapgen[l][m].room_type = RoomTypes.ROOM2
						
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
	#if better_zone_generation:
		#for j in range(room_index + 1):
			## Stop better zone geneartion if there is 2x2 zone and higher
			#if room1_amount[j] < better_zone_generation_min_amount && (map_size_x + 1) * (map_size_y + 1) < 4:
				#rng_seed = -1
				#rng.randomize()
				#start_generation()
				#return

## Clears the map generation
func clear():
	if debug_print:
		print("Clearing the map...")
	disabled_points.clear()
	mapgen.clear()
