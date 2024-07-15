extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

@export var rng_seed: int = -1
## Rooms that will be used
@export var rooms: Array[MapGenZone]
#currently not ported to gdscript
#@export var generate_more_endrooms: bool = false
#@export var generate_more_crossrooms: bool = false
## Map size
@export_range(4, 256, 2) var size: int = 6
## Room in grid size
@export var grid_size: float = 20.48
## Amount of zones
@export var zones_amount: int = 0
### Zone transitions (first transition MUST be 0, last - more then size value, and the rest divide the zones)
#@export var zone_transitions: Array[int] = []
#@export var large_room_support: bool = false
@export_range(1, 5) var room_amount: float = 2

var mapgen: Array[Array] = []

class Room:
	# north, east, west and south check the connection between rooms.
	var exist: bool
	var north: bool
	var south: bool
	var east: bool
	var west: bool
	var room_type: RoomTypes
	var angle: float
	var zone: int

var size_y: int

# Called when the node enters the scene tree for the first time.
func _ready():
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
			mapgen[g][h].zone = 0
	generate_zone_astar()
## DEPRECATED use generate_zone_astar() instead...
#func generate_zone_old():
## center of map is ALWAYS exist.
	#var zone_counter: int = 0
	#var number_of_rooms: int = size * room_amount
	##The map generator works in this way:
	##1.Randomize direction
	##2.Move in the right direction.
	##That's all :)
	#
	#while zone_counter <= zones_amount:
		#mapgen[size / 2][(size_y / (zones_amount + 2) * (zone_counter + 1)) / 2].exist = true
		#var temp_x: int = size / 2
		#var temp_y: int = size_y / (zones_amount + 2) * (zone_counter + 1) / 2
		##if zone_counter != zones_amount:
			##var random_checkpoint_room = mapgen[rng.randi_range(0, size - 1)][size_y / (zones_amount + 1) * (zone_counter + 1)]
			##random_checkpoint_room.exist = true
			##random_checkpoint_room.special = true
		#for i in range(number_of_rooms + 1):
			#var dir: int = rng.randi_range(0, 4)
			#
			#if dir < 1 && temp_x < size - 1:
				#temp_x += 1
				#mapgen[temp_x][temp_y].exist = true
				#if mapgen[temp_x - 1][temp_y].exist:
					#mapgen[temp_x - 1][temp_y].east = true
					#mapgen[temp_x][temp_y].west = true
			#elif dir < 2 && temp_x > 0:
				#temp_x -= 1
				#mapgen[temp_x][temp_y].exist = true
				#if mapgen[temp_x + 1][temp_y].exist:
					#mapgen[temp_x + 1][temp_y].west = true
					#mapgen[temp_x][temp_y].east = true
			#elif dir < 3 && temp_y < (size_y / (zones_amount + 1) * (zone_counter + 1)) - 1:
				#temp_y += 1
				#mapgen[temp_x][temp_y].exist = true
				#if mapgen[temp_x][temp_y - 1].exist:
					#mapgen[temp_x][temp_y - 1].north = true
					#mapgen[temp_x][temp_y].south = true
			#elif dir < 4 && temp_y > 0:
				#temp_y -= 1
				#mapgen[temp_x][temp_y].exist = true
				#if mapgen[temp_x][temp_y + 1].exist:
					#mapgen[temp_x][temp_y + 1].south = true
					#mapgen[temp_x][temp_y].north = true
			#mapgen[temp_x][temp_y].zone = zone_counter
		#zone_counter += 1
		#
	#place_room_positions()
## Main function, that generate the zones
func generate_zone_astar():
	var zone_counter: int = 0
	while zone_counter <= zones_amount:
		var number_of_rooms: int = size * room_amount
		mapgen[size / 2][(size_y / (zones_amount + 2) * (zone_counter + 1)) / 2].exist = true
		var temp_x: int = size / 2
		var temp_y: int = size_y / (zones_amount + 2) * (zone_counter + 1) / 2
		#if necessary_rooms > (size - 2) * 4:
			#printerr("Necessary to spawn rooms more than available room slots, generator won't work further")
			#return
		# Walk before need-to-sapwn rooms runs out
		while number_of_rooms > 0:
			var random_room = Vector2(rng.randi_range(0, mapgen.size() - 1), rng.randi_range(0, size_y / (zones_amount + 1) * (zone_counter + 1) - 1))
			walk_astar(Vector2(temp_x, temp_y), random_room)
			number_of_rooms -= 1
		# Connect two zones
		if zone_counter < zones_amount:
			walk_astar(Vector2(temp_x, temp_y), Vector2(temp_x, size_y / (zones_amount + 2) * (zone_counter + 2) / 2))
		zone_counter += 1
	place_room_positions()
## for future map customization
#func customize_room_connections():
	#for i in range(size):
		#for j in range(size_y):
			#if mapgen[i][j].exist:
				#if i < size - 1:
					#if mapgen[i + 1][j].exist:
						#mapgen[i + 1][j].west = true
						#mapgen[i][j].east = true
				#if i > 0:
					#if mapgen[i - 1][j].exist:
						#mapgen[i - 1][j].east = true
						#mapgen[i][j].west = true
				#if j < size_y - 1:
					#if mapgen[i][j + 1].exist:
						#mapgen[i][j + 1].south = true
						#mapgen[i][j].north = true
				#if j > 0:
					#if mapgen[i][j - 1].exist:
						#mapgen[i][j - 1].north = true
						#mapgen[i][j].south = true
				
			#if rng.randi_range(0, 1) == 1 && mapgen[i][j].north && mapgen[i][j].south && mapgen[i][j].east && mapgen[i][j].west:
				#match rng.randi_range(0, 1):
					#0:
						#mapgen[i][j + 1].south = false
						#mapgen[i][j].north = false
						#mapgen[i][j].south = false
						#mapgen[i][j - 1].north = false
					#1:
						#mapgen[i + 1][j].east = false
						#mapgen[i][j].west = false
						#mapgen[i][j].east = false
						#mapgen[i - 1][j].west = false
	#place_room_positions()

## Main walker function, using AStarGrid2D
func walk_astar(from: Vector2, to: Vector2):
	# Initialization
	var astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, size, size_y)
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
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

func place_room_positions():
	# Check
	for j in range(size):
		for k in range(size_y):
			print(int(mapgen[j][k].exist))
		print()
	
	var room1_amount: int = 0
	var room2_amount: int = 0
	var room2c_amount: int = 0
	var room3_amount: int = 0
	var room4_amount: int = 0
	
	for l in range(size):
		for m in range(size_y):
			var north: bool
			var east: bool
			var south: bool
			var west: bool
			if mapgen[l][m].exist:
				if l > 0:
					west = mapgen[l][m].west
				if l < size - 1:
					east = mapgen[l][m].east
				if m > 0:
					north = mapgen[l][m].north
				if m < size_y - 1:
					south = mapgen[l][m].south
				if north && south:
					if east && west:
						#room4
						var room_angle: Array[float] = [0, 90, 180, 270]
						mapgen[l][m].room_type = RoomTypes.ROOM4
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 3)]
						room4_amount += 1
					elif east && !west:
						#room3, pointing east
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 90
						room3_amount += 1
					elif !east && west:
						#room3, pointing west
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 270
						room3_amount += 1
					else:
						#vertical room2
						var room_angle: Array[float] = [0, 180]
						mapgen[l][m].room_type = RoomTypes.ROOM2
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						room2_amount += 1
				elif east && west:
					if north && !south:
						#room3, pointing north
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 0
						room3_amount += 1
					elif !north && south:
					#room3, pointing south
						mapgen[l][m].room_type = RoomTypes.ROOM3
						mapgen[l][m].angle = 180
						room3_amount += 1
					else:
					#horizontal room2
						var room_angle: Array[float] = [90, 270]
						mapgen[l][m].room_type = RoomTypes.ROOM2
						mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						room2_amount += 1
				elif north:
					if east:
					#room2c, north-east
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 0
						room2c_amount += 1
					elif west:
					#room2c, north-west
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 270
						room2c_amount += 1
					else:
					#room1, north
						mapgen[l][m].room_type = RoomTypes.ROOM1
						mapgen[l][m].angle = 0
						room1_amount += 1
				elif south:
					if east:
					#room2c, south-east
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 90
						room2c_amount += 1
					elif west:
					#room2c, south-west
						mapgen[l][m].room_type = RoomTypes.ROOM2C
						mapgen[l][m].angle = 180
						room2c_amount += 1
					else:
					#room1, south
						mapgen[l][m].room_type = RoomTypes.ROOM1
						mapgen[l][m].angle = 180
						room1_amount += 1
				elif east:
					#room1, east
					mapgen[l][m].room_type = RoomTypes.ROOM1
					mapgen[l][m].angle = 90
					room1_amount += 1
				else:
					#room1, west
					mapgen[l][m].room_type = RoomTypes.ROOM1
					mapgen[l][m].angle = 270
					room1_amount += 1
	spawn_rooms()

## Spawns room prefab on the grid
func spawn_rooms():
	var zone_counter: int = 0
	var selected_room: PackedScene
	var room1_count: Array[int] = [0]
	var room2_count: Array[int] = [0]
	var room2c_count: Array[int] = [0]
	var room3_count: Array[int] = [0]
	var room4_count: Array[int] = [0]
	if zones_amount > 0:
		for i in range(zones_amount):
			room1_count.append(0)
			room2_count.append(0)
			room2c_count.append(0)
			room3_count.append(0)
			room4_count.append(0)
	#spawn a room
	for n in range(size):
		for o in range(size_y):
			if o >= size_y / (zones_amount + 1) * (zone_counter + 1):
				zone_counter += 1
			var room: StaticBody3D
			match mapgen[n][o].room_type:
				RoomTypes.ROOM1:
					
					#for p in range(rooms[zone_counter].endrooms.size()):
						#if rooms[zone_counter].endrooms[p].single && !room1_count.has(p):
							#selected_room = rooms[zone_counter].endrooms[p].prefab
							#room1_count.append(p)
							#break
						#else:
							#if p < rooms[zone_counter].endrooms.size() - 1 && rng.randf() * 100 <= rooms[zone_counter].endrooms[p]:
								#
					
					
					
					if (room1_count[zone_counter] >= rooms[zone_counter].endrooms_single.size()):
						for i in range(rooms[zone_counter].endrooms.size()):
							if rng.randf() * 100 >= rooms[zone_counter].endrooms[i].spawn_chance:
								selected_room = rooms[zone_counter].endrooms[i].prefab
								break
							if i == rooms[zone_counter].endrooms.size() - 1:
								selected_room = rooms[zone_counter].endrooms[i].prefab
					else:
						selected_room = rooms[zone_counter].endrooms_single[room1_count[zone_counter]].prefab
					room1_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM2:
					#if enable_zones && get_zone(o) != get_zone(o + 1):
						#selected_room = checkpoints[get_zone(o) - 1]
					#else:
					if (room1_count[zone_counter] >= rooms[zone_counter].hallways_single.size()):
						for i in range(rooms[zone_counter].hallways.size()):
							if rng.randf() * 100 >= rooms[zone_counter].hallways[i].spawn_chance:
								selected_room = rooms[zone_counter].hallways[i].prefab
								break
							if i == rooms[zone_counter].hallways.size() - 1:
								selected_room = rooms[zone_counter].hallways[i].prefab
					else:
						selected_room = rooms[zone_counter].hallways_single[room1_count[zone_counter]].prefab
					room2_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM2C:
					if (room1_count[zone_counter] >= rooms[zone_counter].corners_single.size()):
						for i in range(rooms[zone_counter].corners.size()):
							if rng.randf() * 100 >= rooms[zone_counter].corners[i].spawn_chance:
								selected_room = rooms[zone_counter].corners[i].prefab
								break
							if i == rooms[zone_counter].corners.size() - 1:
								selected_room = rooms[zone_counter].corners[i].prefab
					else:
						selected_room = rooms[zone_counter].corners_single[room1_count[zone_counter]].prefab
					room2c_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM3:
					if (room1_count[zone_counter] >= rooms[zone_counter].trooms_single.size()):
						for i in range(rooms[zone_counter].trooms.size()):
							if rng.randf() * 100 >= rooms[zone_counter].trooms[i].spawn_chance:
								selected_room = rooms[zone_counter].trooms[i].prefab
								break
							if i == rooms[zone_counter].trooms.size() - 1:
								selected_room = rooms[zone_counter].trooms[i].prefab
					else:
						selected_room = rooms[zone_counter].trooms_single[room1_count[zone_counter]].prefab
					room3_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
				RoomTypes.ROOM4:
					if (room1_count[zone_counter] >= rooms[zone_counter].crossrooms_single.size()):
						for i in range(rooms[zone_counter].crossrooms.size()):
							if rng.randf() * 100 >= rooms[zone_counter].crossrooms[i].spawn_chance:
								selected_room = rooms[zone_counter].crossrooms[i].prefab
								break
							if i == rooms[zone_counter].crossrooms.size() - 1:
								selected_room = rooms[zone_counter].crossrooms[i].prefab
					else:
						selected_room = rooms[zone_counter].crossrooms_single[room1_count[zone_counter]].prefab
					room4_count[zone_counter] += 1
					room = selected_room.instantiate()
					room.position = Vector3(n * grid_size, 0, o * grid_size)
					room.rotation_degrees = Vector3(0, mapgen[n][o].angle, 0)
					add_child(room, true)
		zone_counter = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
