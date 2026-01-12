@icon("res://MapGen/icons/MapGenRender3D.svg")
extends Node3D
class_name FacilityGeneratorRender3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

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

## First array is actually a container, second is zone, third is type container.
## Structure is like: [[[DoubleRoomTypes, DoubleRoomTypes]]] (since enum is actually named int)
var double_room_shapes: Array[Array]

# regular rooms
var room1_count: Array[int] = [0]
var room2_count: Array[int] = [0]
var room2c_count: Array[int] = [0]
var room3_count: Array[int] = [0]
var room4_count: Array[int] = [0]
# large rooms
var room1l_count: Array[int] = [0]
var room2l_count: Array[int] = [0]
var room2cl_count: Array[int] = [0]
var room3l_count: Array[int] = [0]
# double rooms
var room2d_count: Array[int] = [0]
var room4d_count: Array[int] = [0]
var room2cd_count: Array[int] = [0]
var room3d_count: Array[int] = [0]

var cached_scenes: Dictionary[String, PackedScene]

#var semaphore: Semaphore
#var thread: Thread	
#var threads_to_finish: int = 0
#var threaded_gltf_parser_args: Dictionary

var file_counter: int = 0

var gltf_document: GLTFDocument
var gltf_state:GLTFState
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gltf_document = GLTFDocument.new()
	gltf_state = GLTFState.new()

func generate_rooms(path: String):
	if rng_seed != -1:
		rng.seed = rng_seed
	if rooms == null || rooms.size() == 0:
		printerr("There are no zones, cannot spawn.")
		return
	size_x = zone_size * (map_size_x + 1)
	size_y = zone_size * (map_size_y + 1)
	# Initialize, what double room shapes are being used
	#if double_room_support:
		#for i in range(rooms.size()):
			#double_room_shapes.append([])
			#for double_rooms in rooms[i].double_rooms:
				#if double_rooms[0] is MapGenRoom && double_rooms[1] is MapGenRoom:
					#double_room_shapes[i].append([double_rooms[0], double_rooms[1]])
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
	mapgen_core.double_room_support = false
	mapgen_core.double_room_shapes = double_room_shapes
	mapgen_core.mapgen = mapgen
	add_child(mapgen_core)
	#threaded_gltf_parser_args["path_to_save"] = path
	mapgen = mapgen_core.start_generation()
	spawn_rooms(path)

## Spawns room prefab on the grid
func spawn_rooms(path_to_save: String) -> void:
	if debug_print:
		print("Spawning rooms...")
	var ready_to_spawn_rooms: Array[MapGenZone] = rooms.duplicate()
	for i in range(ready_to_spawn_rooms.size()):
		ready_to_spawn_rooms[i] = rooms[i].duplicate(true)
	# Checks the zone
	var zone_counter: Vector2i = Vector2i.ZERO
	var selected_room: PackedScene
	
	var zone_index_default: int = 0
	var zone_index: int = 0

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
			room2d_count.append(0)
			room4d_count.append(0)
			room2cd_count.append(0)
			room3d_count.append(0)
			# we need to add map_size by Y, because the Y grid will be full in previous X:
			# e.g.:
			# 0|2
			# -=-
			# 1|3
			zone_index_default += size_y / (zone_size * (map_size_y + 1))
			zone_index = zone_index_default
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
				room2d_count.append(0)
				room4d_count.append(0)
				room2cd_count.append(0)
				room3d_count.append(0)
				zone_index += 1
			var room: Node3D
			#var thread_started: bool = false
			#while threads_to_finish >= OS.get_processor_count() / 2:
				#if !thread_started:
					#semaphore.post(OS.get_processor_count() / 2)
					#thread_started = true
				#continue
			if mapgen[n][o].resource == null:
				match mapgen[n][o].room_type:
					RoomTypes.ROOM1:
						if mapgen[n][o].large && large_rooms && rooms[zone_index].endrooms_single_large.size() > 0 && room1l_count[zone_index] < rooms[zone_index].endrooms_single_large.size():
							# Large rooms spawn, when large_rooms enabled
							selected_room = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].endrooms_single_large[room1l_count[zone_index]]
							room1l_count[zone_index] += 1
						else:
							selected_room = room_select(RoomTypes.ROOM1, ready_to_spawn_rooms, zone_index, n, o)
						
						if selected_room != null:
							room = selected_room.instantiate()
							room.position = Vector3(n * grid_size, 0, o * grid_size)
							room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
							
							
							gltf_document.append_from_scene(room, gltf_state)
							gltf_document.write_to_filesystem(gltf_state, path_to_save.get_basename() + "-" + str(file_counter) + "." + path_to_save.get_extension())
							room.free()
							await get_tree().process_frame
							if debug_print:
								print(gltf_state.get_reference_count())
							
							gltf_state = GLTFState.new()
						elif selected_room == null && (mapgen[n][o].resource.gltf_path != null || !mapgen[n][o].resource.gltf_path.is_empty()):
							#threaded_gltf_parser_args["path"] = mapgen[n][o].resource.gltf_path
							#threaded_gltf_parser_args["position_x"] = n
							#threaded_gltf_parser_args["position_y"] = o
							#threaded_gltf_parser_args["angle"] = mapgen[n][o].angle
							#thread.start(load_gltf)
							#threads_to_finish += 1
							load_gltf(mapgen[n][o].resource.gltf_path, path_to_save, n, o, mapgen[n][o].angle)
						else:
							printerr("No PackedScene or GLTF path are valid. Stopping map generator.")
							return
						
						file_counter += 1
						
					RoomTypes.ROOM2:
						if mapgen[n][o].checkpoint && checkpoints_enabled:
							# Checkpoint room spawn
							mapgen[n][o].resource = rooms[zone_index].checkpoint_hallway[rng.randi_range(0, rooms[zone_index].checkpoint_hallway.size() - 1)]
							selected_room = rooms[zone_index].checkpoint_hallway[rng.randi_range(0, rooms[zone_index].checkpoint_hallway.size() - 1)].prefab
							room2_count[zone_index] += 1
						elif mapgen[n][o].large && large_rooms && rooms[zone_index].hallways_single_large.size() > 0 && room2l_count[zone_index] < rooms[zone_index].hallways_single_large.size():
							# Large rooms spawn, when large_rooms enabled
							selected_room = rooms[zone_index].hallways_single_large[room2l_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].hallways_single_large[room2l_count[zone_index]]
							room2l_count[zone_index] += 1
						else:
							selected_room = room_select(RoomTypes.ROOM2, ready_to_spawn_rooms, zone_index, n, o)
						
						if selected_room != null:
							room = selected_room.instantiate()
							room.position = Vector3(n * grid_size, 0, o * grid_size)
							room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
							gltf_document.append_from_scene(room, gltf_state)
							gltf_document.write_to_filesystem(gltf_state, path_to_save.get_basename() + "-" + str(file_counter) + "." + path_to_save.get_extension())
							room.free()
							await get_tree().process_frame
							if debug_print:
								print(gltf_state.get_reference_count())
							gltf_state = GLTFState.new()
						elif selected_room == null && (mapgen[n][o].resource.gltf_path != null || !mapgen[n][o].resource.gltf_path.is_empty()):
							#threaded_gltf_parser_args["path"] = mapgen[n][o].resource.gltf_path
							#threaded_gltf_parser_args["position_x"] = n
							#threaded_gltf_parser_args["position_y"] = o
							#threaded_gltf_parser_args["angle"] = mapgen[n][o].angle
							#thread.start(load_gltf)
							#threads_to_finish += 1
							load_gltf(mapgen[n][o].resource.gltf_path, path_to_save, n, o, mapgen[n][o].angle)
						else:
							printerr("No PackedScene or GLTF path are valid. Stopping map generator.")
							return
						
						file_counter += 1
						
					RoomTypes.ROOM2C:
						if mapgen[n][o].large && large_rooms && rooms[zone_index].corners_single_large.size() > 0 && room2cl_count[zone_index] < rooms[zone_index].corners_single_large.size():
							# Large rooms spawn, when large_rooms enabled
							selected_room = rooms[zone_index].corners_single_large[room2cl_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].corners_single_large[room2cl_count[zone_index]]
							room2cl_count[zone_index] += 1
						else:
							selected_room = room_select(RoomTypes.ROOM2C, ready_to_spawn_rooms, zone_index, n, o)
						
						if selected_room != null:
							room = selected_room.instantiate()
							room.position = Vector3(n * grid_size, 0, o * grid_size)
							room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
							gltf_document.append_from_scene(room, gltf_state)
							gltf_document.write_to_filesystem(gltf_state, path_to_save.get_basename() + "-" + str(file_counter) + "." + path_to_save.get_extension())
							room.free()
							await get_tree().process_frame
							if debug_print:
								print(gltf_state.get_reference_count())
							gltf_state = GLTFState.new()
						elif selected_room == null && (mapgen[n][o].resource.gltf_path != null || !mapgen[n][o].resource.gltf_path.is_empty()):
							#threaded_gltf_parser_args["path"] = mapgen[n][o].resource.gltf_path
							#threaded_gltf_parser_args["position_x"] = n
							#threaded_gltf_parser_args["position_y"] = o
							#threaded_gltf_parser_args["angle"] = mapgen[n][o].angle
							#thread.start(load_gltf)
							#threads_to_finish += 1
							load_gltf(mapgen[n][o].resource.gltf_path, path_to_save, n, o, mapgen[n][o].angle)
						else:
							printerr("No PackedScene or GLTF path are valid. Stopping map generator.")
							return
						
						file_counter += 1
						
					RoomTypes.ROOM3:
						if mapgen[n][o].large && large_rooms && rooms[zone_index].trooms_single_large.size() > 0 && room3l_count[zone_index] < rooms[zone_index].trooms_single_large.size():
							# Large rooms spawn, when large_rooms enabled
							selected_room = rooms[zone_index].trooms_single_large[room3l_count[zone_index]].prefab
							mapgen[n][o].resource = rooms[zone_index].trooms_single_large[room3l_count[zone_index]]
							room3l_count[zone_index] += 1
						else:
							selected_room = room_select(RoomTypes.ROOM3, ready_to_spawn_rooms, zone_index, n, o)
						
						if selected_room != null:
							room = selected_room.instantiate()
							room.position = Vector3(n * grid_size, 0, o * grid_size)
							room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
							gltf_document.append_from_scene(room, gltf_state)
							gltf_document.write_to_filesystem(gltf_state, path_to_save.get_basename() + "-" + str(file_counter) + "." + path_to_save.get_extension())
							room.free()
							await get_tree().process_frame
							if debug_print:
								print(gltf_state.get_reference_count())
							gltf_state = GLTFState.new()
							
						elif selected_room == null && (mapgen[n][o].resource.gltf_path != null || !mapgen[n][o].resource.gltf_path.is_empty()):
							#threaded_gltf_parser_args["path"] = mapgen[n][o].resource.gltf_path
							#threaded_gltf_parser_args["position_x"] = n
							#threaded_gltf_parser_args["position_y"] = o
							#threaded_gltf_parser_args["angle"] = mapgen[n][o].angle
							#thread.start(load_gltf)
							#threads_to_finish += 1
							load_gltf(mapgen[n][o].resource.gltf_path, path_to_save, n, o, mapgen[n][o].angle)
						else:
							printerr("No PackedScene or GLTF path are valid. Stopping map generator.")
							return
						
						file_counter += 1
						
					RoomTypes.ROOM4:
						selected_room = room_select(RoomTypes.ROOM4, ready_to_spawn_rooms, zone_index, n, o)
						
						if selected_room != null:
							room = selected_room.instantiate()
							room.position = Vector3(n * grid_size, 0, o * grid_size)
							room.rotation_degrees = Vector3(room.rotation_degrees.x, mapgen[n][o].angle, room.rotation_degrees.z)
							gltf_document.append_from_scene(room, gltf_state)
							gltf_document.write_to_filesystem(gltf_state, path_to_save.get_basename() + "-" + str(file_counter) + "." + path_to_save.get_extension())
							room.free()
							await get_tree().process_frame
							if debug_print:
								print(gltf_state.get_reference_count())
							gltf_state = GLTFState.new()
						elif selected_room == null && (mapgen[n][o].resource.gltf_path != null || !mapgen[n][o].resource.gltf_path.is_empty()):
							#threaded_gltf_parser_args["path"] = mapgen[n][o].resource.gltf_path
							#threaded_gltf_parser_args["position_x"] = n
							#threaded_gltf_parser_args["position_y"] = o
							#threaded_gltf_parser_args["angle"] = mapgen[n][o].angle
							#thread.start(load_gltf)
							#threads_to_finish += 1
							load_gltf(mapgen[n][o].resource.gltf_path, path_to_save, n, o, mapgen[n][o].angle)
						else:
							printerr("No PackedScene or GLTF path are valid. Stopping map generator.")
							return
						
						file_counter += 1
						
		zone_index = zone_index_default
		zone_counter.y = 0
	if enable_door_generation:
		spawn_doors()
	
	clear()

func room_select(type: RoomTypes, ready_to_spawn_rooms: Array[MapGenZone], zone_index: int, n: int, o: int) -> PackedScene:
	var selected_room: PackedScene
	match type:
		RoomTypes.ROOM1:
			var single_room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].endrooms_single, true)
			var room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].endrooms)
			if single_room_data != null:
				var spawn_chance = rng.randf_range(0.0, single_room_data.spawn_chance + room_data.spawn_chance)
				if (room1_count[zone_index] < rooms[zone_index].endrooms_single.size() && spawn_chance < single_room_data.spawn_chance) || single_room_data.guaranteed_spawn:
					# Single rooms spawn
					mapgen[n][o].resource = single_room_data
					selected_room = single_room_data.prefab
					room1_count[zone_index] += 1
				else:
					# Generic room spawn
					mapgen[n][o].resource = room_data
					selected_room = room_data.prefab
					ready_to_spawn_rooms[zone_index].endrooms_single.append(single_room_data)
			else:
				# Generic room spawn
				mapgen[n][o].resource = room_data
				selected_room = room_data.prefab
		RoomTypes.ROOM2:
			var single_room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].hallways_single, true)
			var room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].hallways)
			if single_room_data != null:
				var spawn_chance = rng.randf_range(0.0, single_room_data.spawn_chance + room_data.spawn_chance)
				if (room2_count[zone_index] < rooms[zone_index].hallways_single.size() && spawn_chance < single_room_data.spawn_chance) || single_room_data.guaranteed_spawn:
					# Single rooms spawn
					mapgen[n][o].resource = single_room_data
					selected_room = single_room_data.prefab
					room2_count[zone_index] += 1
				else:
					# Generic room spawn
					mapgen[n][o].resource = room_data
					selected_room = room_data.prefab
					ready_to_spawn_rooms[zone_index].hallways_single.append(single_room_data)
			else:
				# Generic room spawn
				mapgen[n][o].resource = room_data
				selected_room = mapgen[n][o].resource.prefab
		RoomTypes.ROOM2C:
			var single_room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].corners_single, true)
			var room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].corners)
			if single_room_data != null:
				var spawn_chance = rng.randf_range(0.0, single_room_data.spawn_chance + room_data.spawn_chance)
				if (room2c_count[zone_index] < rooms[zone_index].corners_single.size() && spawn_chance < single_room_data.spawn_chance) || single_room_data.guaranteed_spawn:
					# Single rooms spawn
					mapgen[n][o].resource = single_room_data
					selected_room = single_room_data.prefab
					room2c_count[zone_index] += 1
				else:
					# Generic room spawn
					mapgen[n][o].resource = room_data
					selected_room = room_data.prefab
					ready_to_spawn_rooms[zone_index].corners_single.append(single_room_data)
			else:
				# Generic room spawn
				mapgen[n][o].resource = room_data
				selected_room = mapgen[n][o].resource.prefab
		RoomTypes.ROOM3:
			var single_room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].trooms_single, true)
			var room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].trooms)
			if single_room_data != null:
				var spawn_chance = rng.randf_range(0.0, single_room_data.spawn_chance + room_data.spawn_chance)
				if (room3_count[zone_index] < rooms[zone_index].trooms_single.size() && spawn_chance < single_room_data.spawn_chance) || single_room_data.guaranteed_spawn:
					# Single rooms spawn
					mapgen[n][o].resource = single_room_data
					selected_room = single_room_data.prefab
					room3_count[zone_index] += 1
				else:
					# Generic room spawn
					mapgen[n][o].resource = room_data
					selected_room = room_data.prefab
					ready_to_spawn_rooms[zone_index].trooms_single.append(single_room_data)
			else:
				# Generic room spawn
				mapgen[n][o].resource = room_data
				selected_room = mapgen[n][o].resource.prefab
		RoomTypes.ROOM4:
			var single_room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].crossrooms_single, true)
			var room_data: MapGenRoom = random_room_with_chance(ready_to_spawn_rooms[zone_index].crossrooms)
			if single_room_data != null:
				var spawn_chance = rng.randf_range(0.0, single_room_data.spawn_chance + room_data.spawn_chance)
				if (room4_count[zone_index] < rooms[zone_index].crossrooms_single.size() && spawn_chance < single_room_data.spawn_chance) || single_room_data.guaranteed_spawn:
					# Single rooms spawn
					mapgen[n][o].resource = single_room_data
					selected_room = single_room_data.prefab
					room4_count[zone_index] += 1
				else:
					# Generic room spawn
					mapgen[n][o].resource = room_data
					selected_room = room_data.prefab
					ready_to_spawn_rooms[zone_index].crossrooms_single.append(single_room_data)
			else:
				# Generic room spawn
				mapgen[n][o].resource = room_data
				selected_room = mapgen[n][o].resource.prefab
	return selected_room

## Returns random room, depending on chance
func random_room_with_chance(rooms_pack: Array[MapGenRoom], single: bool = false) -> MapGenRoom:
	var counter: float = 0.0
	var prev_counter: float = 0.0
	var room: MapGenRoom
	var all_spawn_chances: Array[float] = []
	var spawn_chances: float = 0
	for j in range(rooms_pack.size()):
		if j >= rooms_pack.size():
			break
		if single && rooms_pack[j].guaranteed_spawn:
			room = rooms_pack[j]
			break
		all_spawn_chances.append(rooms_pack[j].spawn_chance)
		spawn_chances += rooms_pack[j].spawn_chance
	var random_room: float = rng.randf_range(0.0, spawn_chances)
	if room == null:
		for i in range(all_spawn_chances.size()):
			counter += all_spawn_chances[i]
			if (random_room < counter && random_room >= prev_counter) || i == all_spawn_chances.size() - 1:
				room = rooms_pack[i]
				break
			prev_counter = counter
		all_spawn_chances.clear()
	counter = 0
	prev_counter = 0
	if single:
		rooms_pack.erase(room)
	return room

## Spawn doors
func spawn_doors() -> void:
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
		if i >= size_x / (map_size_x + 1) * (zone_counter.x + 1) - 1:
			if checkpoints_enabled && rooms[zone_index].door_frames.size() > 0:
				for k in range(size_y):
					if mapgen[i][k].east:
						var door: Node3D = rooms[zone_index].checkpoint_door_frames[rng.randi_range(0, rooms[zone_index].checkpoint_door_frames.size() - 1)].instantiate()
						door.position = global_position + Vector3(i * grid_size + grid_size / 2, 0, k * grid_size)
						door.rotation_degrees = Vector3(0, 0, 0)
						startup_node.add_child(door, true)
			zone_counter.x += 1
			zone_index_default += map_size_y + 1
		for j in range(size_y):
			if j >= size_y / (map_size_y + 1) * (zone_counter.y + 1) - 1:
				if checkpoints_enabled && rooms[zone_index].door_frames.size() > 0:
					if mapgen[i][j].north:
						var door: Node3D = rooms[zone_index].checkpoint_door_frames[rng.randi_range(0, rooms[zone_index].checkpoint_door_frames.size() - 1)].instantiate()
						door.position = global_position + Vector3(i * grid_size, 0, j * grid_size + grid_size / 2)
						door.rotation_degrees = Vector3(0, 0, 0)
						startup_node.add_child(door, true)
				zone_counter.y += 1
				zone_index += 1
			elif rooms[zone_index].door_frames.size() > 0:
				var available_frames: Array[PackedScene] = rooms[zone_index].door_frames
				if mapgen[i][j].east:
					var door: Node3D
					if mapgen[i+1][j].double_room && mapgen[i][j].double_room:
						continue
					if mapgen[i+1][j].resource.door_type >= 0: # Spawn specific door frame
						door = available_frames[mapgen[i+1][j].resource.door_type].instantiate()
					elif mapgen[i][j].resource.door_type >= 0:
						door = available_frames[mapgen[i][j].resource.door_type].instantiate()
					else: # Spawn random door frame
						door = available_frames[rng.randi_range(0, available_frames.size() - 1)].instantiate()
					if door != null:
						door.position = global_position + Vector3(i * grid_size + grid_size / 2, 0, j * grid_size)
						door.rotation_degrees = Vector3(0, 90, 0)
						startup_node.add_child(door, true)
				if mapgen[i][j].north:
					var door: Node3D
					if mapgen[i][j+1].double_room && mapgen[i][j].double_room:
						continue
					if mapgen[i][j+1].resource.door_type >= 0: # Spawn specific door frame
						door = available_frames[mapgen[i][j+1].resource.door_type].instantiate()
					elif mapgen[i][j].resource.door_type >= 0:
						door = available_frames[mapgen[i][j].resource.door_type].instantiate()
					else: # Spawn random door frame
						door = available_frames[rng.randi_range(0, available_frames.size() - 1)].instantiate()
					if door != null:
						door.position = global_position + Vector3(i * grid_size, 0, j * grid_size + grid_size / 2)
						door.rotation_degrees = Vector3(0, 0, 0)
						startup_node.add_child(door, true)
		zone_index = zone_index_default
		zone_counter.y = 0

## Clears the map generation
func clear():
	mapgen.clear()
	size_x = 0
	size_y = 0
	# regular rooms
	room1_count = [0]
	room2_count = [0]
	room2c_count = [0]
	room3_count = [0]
	room4_count = [0]
# large rooms
	room1l_count = [0]
	room2l_count = [0]
	room2cl_count = [0]
	room3l_count = [0]
# double rooms
	room2d_count = [0]
	room4d_count = [0]
	room2cd_count = [0]
	room3d_count = [0]
	for node in get_children():
		node.queue_free()
	cached_scenes.clear()

func load_gltf(gltf_path: String, output_path: String, position_x: int, position_y: int, angle: float):
	#semaphore.wait()
	#if cached_scenes.has(path):
		#return cached_scenes[path].instantiate()
	gltf_state = GLTFState.new()
	var error = gltf_document.append_from_file(gltf_path, gltf_state)
	if error == OK:
		#var nodes: Array[GLTFNode] = gltf_state.get_nodes()
		#for i in gltf_state.root_nodes:
			#for j in nodes[i].children:
				#nodes[j].position = Vector3(position_x * grid_size, 0, position_y * grid_size)
				#var root_node_rotation: Vector3 = nodes[i].rotation.get_euler()
				#nodes[j].rotation = Quaternion.from_euler(Vector3(root_node_rotation.x, angle, root_node_rotation.z))
		
		var gltf_scene_root_node = gltf_document.generate_scene(gltf_state)
		gltf_scene_root_node.position = Vector3(position_x * grid_size, 0, position_y * grid_size)
		gltf_scene_root_node.rotation_degrees = Vector3(gltf_scene_root_node.rotation_degrees.x, angle, gltf_scene_root_node.rotation_degrees.z)
		add_child(gltf_scene_root_node)
		gltf_state = GLTFState.new()
		gltf_document.append_from_scene(gltf_scene_root_node, gltf_state)
		# The file extension in the output `path` (`.gltf` or `.glb`) determines
		# whether the output uses text or binary format.
		# `GLTFDocument.generate_buffer()` is also available for saving to memory.
		#var path_to_save: String = threaded_gltf_parser_args["path_to_save"] as String
		gltf_document.write_to_filesystem(gltf_state, output_path.get_basename() + "-" + str(file_counter) + "." + output_path.get_extension())
		gltf_scene_root_node.free()
		await get_tree().process_frame
		if debug_print:
			print(gltf_state.get_reference_count())
		gltf_state = GLTFState.new()
		#var packed_scene:PackedScene = PackedScene.new()
		#packed_scene.pack(gltf_scene_root_node)
		#if !DirAccess.dir_exists_absolute("user://temporary_scenes/"):
			#DirAccess.make_dir_absolute("user://temporary_scenes/")
		#ResourceSaver.save(packed_scene, "user://temporary_scenes/" + path.get_file().split(".")[0] + ".tscn")
		#cached_scenes[path] = packed_scene
	else:
		printerr("GLTF parsing error")
	

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			for key in cached_scenes:
				cached_scenes.clear()
