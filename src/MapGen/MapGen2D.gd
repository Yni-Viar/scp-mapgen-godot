@icon("res://MapGen/icons/MapGenNode2D.svg")
extends Node2D
class_name FacilityGenerator2D

signal generated

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

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
## /!\ WARNING! The checkpoint room behaves differently, than SCP - Cont. Breach checkpoints,
## they behave like SCP: Secret Lab. HCZ-EZ checkpoints, with two rooms.
@export var checkpoints_enabled: bool = false
## Prints map seed
@export var debug_print: bool = false

var mapgen: Array[Array] = []

var size_x: int
var size_y: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func generate_rooms():
	clear()
	size_x = zone_size * (map_size_x + 1)
	size_y = zone_size * (map_size_y + 1)
	var mapgen_core: MapGenCore = MapGenCore.new()
	mapgen_core.rng_seed = rng_seed
	mapgen_core.rooms = rooms
	mapgen_core.zone_size = zone_size
	mapgen_core.map_size_x = map_size_x
	mapgen_core.map_size_y = map_size_y
	mapgen_core.large_rooms = large_rooms
	mapgen_core.room_amount = room_amount
	mapgen_core.better_zone_generation = better_zone_generation
	mapgen_core.better_zone_generation_min_amount = better_zone_generation_min_amount
	mapgen_core.checkpoints_enabled = checkpoints_enabled
	mapgen_core.debug_print = debug_print
	mapgen_core.mapgen = mapgen
	add_child(mapgen_core)
	mapgen = mapgen_core.start_generation()
	spawn_rooms()

#spawn_rooms()

## Spawns room prefab on the grid
func spawn_rooms() -> void:
	if debug_print:
		print("Spawning rooms...")
	# Checks the zone
	var zone_counter: Vector2i = Vector2i.ZERO
	#var selected_room: MapGenRoom
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
			var room: Sprite2D
			match mapgen[n][o].room_type:
				RoomTypes.ROOM1:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].endrooms_single_large.size() > 0 && room1l_count[zone_index] < rooms[zone_index].endrooms_single_large.size():
						#selected_room = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]]
						mapgen[n][o].resource = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]]
						room1l_count[zone_index] += 1
					else:
						if rooms[zone_index].endrooms_single_large.size() > 0 && !large_rooms && room1l_count[zone_index] < rooms[zone_index].endrooms_single_large.size():
							#selected_room = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]]
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
									#selected_room = rooms[zone_index].endrooms[i]
									mapgen[n][o].resource = rooms[zone_index].endrooms[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							#selected_room = rooms[zone_index].endrooms_single[room1_count[zone_index]]
							mapgen[n][o].resource = rooms[zone_index].endrooms_single[room1_count[zone_index]]
							room1_count[zone_index] += 1
					
					#room = selected_room.instantiate()
					#room.position = Vector2(n * grid_size, o * grid_size)
					#room.rotation_degrees = mapgen[n][o].angle
					#add_child(room, true)
					#mapgen[n][o].room_name = room.name
				RoomTypes.ROOM2:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].hallways_single_large.size() > 0 && room2l_count[zone_index] < rooms[zone_index].hallways_single_large.size():
						#selected_room = rooms[zone_index].hallways_single_large[room2l_count[zone_index]]
						mapgen[n][o].resource = rooms[zone_index].hallways_single_large[room2l_count[zone_index]]
						room2l_count[zone_index] += 1
					if mapgen[n][o].checkpoint && checkpoints_enabled:
						mapgen[n][o].resource = rooms[zone_index].checkpoint_hallway[rng.randi_range(0, rooms[zone_index].checkpoint_hallway.size() - 1)]
						room2_count[zone_index] += 1
					else:
						if rooms[zone_index].hallways_single_large.size() > 0 && !large_rooms && room2l_count[zone_index] < rooms[zone_index].hallways_single_large.size():
							#selected_room = rooms[zone_index].hallways_single_large[room2l_count[zone_index]]
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
									#selected_room = rooms[zone_index].hallways[i]
									mapgen[n][o].resource = rooms[zone_index].hallways[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							#selected_room = rooms[zone_index].hallways_single[room2_count[zone_index]]
							mapgen[n][o].resource = rooms[zone_index].hallways_single[room2_count[zone_index]]
							room2_count[zone_index] += 1
					#room = selected_room.instantiate()
					#room.position = Vector2(n * grid_size, o * grid_size)
					#room.rotation_degrees = mapgen[n][o].angle
					#add_child(room, true)
					#mapgen[n][o].room_name = room.name
				RoomTypes.ROOM2C:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].corners_single_large.size() > 0 && room2cl_count[zone_index] < rooms[zone_index].corners_single_large.size():
						#selected_room = rooms[zone_index].corners_single_large[room2cl_count[zone_index]]
						mapgen[n][o].resource = rooms[zone_index].corners_single_large[room2cl_count[zone_index]]
						room2cl_count[zone_index] += 1
					else:
						if rooms[zone_index].corners_single_large.size() > 0 && !large_rooms && room2cl_count[zone_index] < rooms[zone_index].corners_single_large.size():
							#selected_room = rooms[zone_index].corners_single_large[room2cl_count[zone_index]]
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
									#selected_room = rooms[zone_index].corners[i]
									mapgen[n][o].resource = rooms[zone_index].corners[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							#selected_room = rooms[zone_index].corners_single[room2c_count[zone_index]]
							mapgen[n][o].resource = rooms[zone_index].corners_single[room2c_count[zone_index]]
							room2c_count[zone_index] += 1
					#room = selected_room.instantiate()
					#room.position = Vector2(n * grid_size, o * grid_size)
					#room.rotation_degrees = mapgen[n][o].angle
					#add_child(room, true)
					#mapgen[n][o].room_name = room.name
				RoomTypes.ROOM3:
					if mapgen[n][o].large && large_rooms && rooms[zone_index].trooms_single_large.size() > 0 && room3l_count[zone_index] < rooms[zone_index].trooms_single_large.size():
						#selected_room = rooms[zone_index].trooms_single_large[room3l_count[zone_index]]
						mapgen[n][o].resource = rooms[zone_index].trooms_single_large[room3l_count[zone_index]]
						room3l_count[zone_index] += 1
					else:
						if rooms[zone_index].trooms_single_large.size() > 0 && !large_rooms && room3l_count[zone_index] < rooms[zone_index].trooms_single_large.size():
							#selected_room = rooms[zone_index].trooms_single_large[room3l_count[zone_index]]
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
									#selected_room = rooms[zone_index].trooms[i]
									mapgen[n][o].resource = rooms[zone_index].trooms[i]
									break
								prev_counter = counter
							all_spawn_chances.clear()
							counter = 0
							prev_counter = 0
						else:
							#selected_room = rooms[zone_index].trooms_single[room3_count[zone_index]]
							mapgen[n][o].resource = rooms[zone_index].trooms_single[room3_count[zone_index]]
							room3_count[zone_index] += 1
					#room = selected_room.instantiate()
					#room.position = Vector2(n * grid_size, o * grid_size)
					#room.rotation_degrees = mapgen[n][o].angle
					#add_child(room, true)
					#mapgen[n][o].room_name = room.name
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
								#selected_room = rooms[zone_index].crossrooms[i]
								mapgen[n][o].resource = rooms[zone_index].crossrooms[i]
								break
							prev_counter = counter
						all_spawn_chances.clear()
						counter = 0
						prev_counter = 0
					else:
						mapgen[n][o].resource = rooms[zone_index].crossrooms_single[room4_count[zone_index]]
						room4_count[zone_index] += 1
					#room = selected_room
					#room.position = Vector2(n * grid_size, o * grid_size)
					#room.rotation_degrees = mapgen[n][o].angle
					#add_child(room, true)
					#mapgen[n][o].room_name = room.name
			if mapgen[n][o].exist:
				room = Sprite2D.new()
				match mapgen[n][o].angle:
					0.0: # this weird sort is due to Control UI type, which behaves differently.
						if mapgen[n][o].room_type == RoomTypes.ROOM2C:
							room.texture = mapgen[n][o].resource.icon_0_degrees
						else:
							room.texture = mapgen[n][o].resource.icon_90_degrees
					90.0:
						if mapgen[n][o].room_type == RoomTypes.ROOM2C:
							room.texture = mapgen[n][o].resource.icon_270_degrees
						else:
							room.texture = mapgen[n][o].resource.icon_0_degrees
					180.0:
						if mapgen[n][o].room_type == RoomTypes.ROOM2C:
							room.texture = mapgen[n][o].resource.icon_180_degrees
						else:
							room.texture = mapgen[n][o].resource.icon_270_degrees
					270.0:
						if mapgen[n][o].room_type == RoomTypes.ROOM2C:
							room.texture = mapgen[n][o].resource.icon_90_degrees
						else:
							room.texture = mapgen[n][o].resource.icon_180_degrees
				room.position = Vector2(n * grid_size, o * grid_size)
				add_child(room, true)
				mapgen[n][o].room_name = room.name
		zone_counter.y = 0
		zone_index = zone_index_default
	#if enable_door_generation:
		#spawn_doors()
	generated.emit()
## Spawn doors
func spawn_doors():
	print("Spawning doors currently not implemented in 2D map generator.")
	#if debug_print:
		#print("Spawning doors...")
	## Checks the zone
	#var zone_counter: Vector2i = Vector2i.ZERO
	#var zone_index: int = 0
	#var zone_index_default: int = 0
	#var startup_node: Node = Node.new()
	#startup_node.name = "DoorFrames"
	#add_child(startup_node)
	#for i in range(size_x):
		#if i >= size_x / (map_size_x + 1) * (zone_counter.x + 1):
			#zone_counter.x += 1
			#zone_index_default += map_size_y + 1
		#for j in range(size_y):
			#if j >= size_y / (map_size_y + 1) * (zone_counter.y + 1):
				#zone_counter.y += 1
				#zone_index += 1
			#if rooms[zone_index].door_frames.size() > 0:
				#var available_frames: Array[PackedScene] = rooms[zone_index].door_frames
				#if mapgen[i][j].east:
					#var door: Node2D = available_frames[rng.randi_range(0, available_frames.size() - 1)].instantiate()
					#door.position = global_position + Vector2(i * grid_size + grid_size / 2, j * grid_size)
					#door.rotation_degrees = 90
					#startup_node.add_child(door, true)
				#if mapgen[i][j].north:
					#var door: Node2D = available_frames[rng.randi_range(0, available_frames.size() - 1)].instantiate()
					#door.position = global_position + Vector2(i * grid_size, j * grid_size + grid_size / 2)
					#door.rotation_degrees = 0
					#startup_node.add_child(door, true)
		#zone_index = zone_index_default
		#zone_counter.y = 0

func clear():
	mapgen.clear()
	size_x = 0
	size_y = 0
	for node in get_children():
		node.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
