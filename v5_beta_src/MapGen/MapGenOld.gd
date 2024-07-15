extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

enum RoomTypes {EMPTY, ROOM1, ROOM2, ROOM2C, ROOM3, ROOM4}

@export var rng_seed: int = -1
## Rooms that will be used
#@export var rooms: Array[MapGenResource]
#currently not ported to gdscript
#@export var generate_more_endrooms: bool = false
#@export var generate_more_crossrooms: bool = false
## Map size
@export_range(8, 256, 2) var size: int = 12
## How complex will be the generation
@export var drill_amount: int = 5
## Room in grid size
@export var grid_size: float = 20.48
## Amount of zones
@export var zones_amount: int = 0
### Zone transitions (first transition MUST be 0, last - more then size value, and the rest divide the zones)
#@export var zone_transitions: Array[int] = []
@export var large_room_support: bool = false

class Room:
	# north, east, west and south check the connection between rooms.
	var exist: bool
	var north: bool
	var south: bool
	var east: bool
	var west: bool
	var room_type: RoomTypes
	var angle: float

func generate_zone():
	var number_of_rooms: int = size * 4
	var mapgen: Array[Array] = []
	# fill with zeros
	for g in range(size):
		mapgen.append([])
		for h in range(size):
			mapgen[g].append(Room.new())
			mapgen[g][h].exist = false
			mapgen[g][h].north = false
			mapgen[g][h].south = false
			mapgen[g][h].east = false
			mapgen[g][h].west = false
			mapgen[g][h].room_type = RoomTypes.EMPTY
			mapgen[g][h].angle = 0
	# center of map is ALWAYS exist.
	mapgen[size / 2][size / 2].exist = true
	var temp_x: int = size / 2
	var temp_y: int = size / 2
	
	#The map generator works in this way:
	#1.Randomize direction
	#2.Move in the right direction.
	#That's all :)
	
	
	for i in range(number_of_rooms + 1):
		var dir: int = rng.randi_range(0, 4)
		
		if dir < 1 && temp_x < size - 1:
			temp_x += 1
			mapgen[temp_x][temp_y].exist = true
			if mapgen[temp_x - 1][temp_y].exist:
				mapgen[temp_x - 1][temp_y].east = true
				mapgen[temp_x][temp_y].west = true
		elif dir < 2 && temp_x > 0:
			temp_x -= 1
			mapgen[temp_x][temp_y].exist = true
			if mapgen[temp_x + 1][temp_y].exist:
				mapgen[temp_x + 1][temp_y].west = true
				mapgen[temp_x][temp_y].east = true
		elif dir < 3 && temp_y < size - 1:
			temp_y += 1
			mapgen[temp_x][temp_y].exist = true
			if mapgen[temp_x][temp_y - 1].exist:
				mapgen[temp_x][temp_y - 1].north = true
				mapgen[temp_x][temp_y].south = true
		elif dir < 4 && temp_y > 0:
			temp_y -= 1
			mapgen[temp_x][temp_y].exist = true
			if mapgen[temp_x][temp_y + 1].exist:
				mapgen[temp_x][temp_y + 1].south = true
				mapgen[temp_x][temp_y].north = true
	
	
	
	for j in range(size):
		for k in range(size):
			print(int(mapgen[j][k].exist))
		print()
	
	#var room1_amount: int = 0
	#var room2_amount: int = 0
	#var room2c_amount: int = 0
	#var room3_amount: int = 0
	#var room4_amount: int = 0
	#
	#for l in range(size):
		#for m in range(size):
			#var north: bool
			#var east: bool
			#var south: bool
			#var west: bool
			##if mapgen[l][m].angle == 180:
				##continue
			#if mapgen[l][m].angle == 0:
				#if l > 0:
					#west = mapgen[l][m].west
				#if l < size - 1:
					#east = mapgen[l][m].east
				#if m > 0:
					#north = mapgen[l][m].north
				#if m < 11:
					#south = mapgen[l][m].south
				#if north && south:
					#if east && west:
						##room4
						#var room_angle: Array[float] = [0, 90, 180, 270]
						#mapgen[l][m].type = RoomTypes.ROOM4
						#mapgen[l][m].angle = room_angle[rng.randi_range(0, 3)]
						#room4_amount += 1
					#elif east && !west:
						##room3, pointing east
						#mapgen[l][m].type = RoomTypes.ROOM3
						#mapgen[l][m].angle = 90
						#room3_amount += 1
					#elif !east && west:
						##room3, pointing west
						#mapgen[l][m].type = RoomTypes.ROOM3
						#mapgen[l][m].angle = 270
						#room3_amount += 1
					#else:
						##vertical room2
						#var room_angle: Array[float] = [0, 180]
						#mapgen[l][m].type = RoomTypes.ROOM2
						#mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						#room2_amount += 1
				#elif east && west:
					#if north && !south:
						##room3, pointing north
						#mapgen[l][m].type = RoomTypes.ROOM3
						#mapgen[l][m].angle = 180
						#room3_amount += 1
					#elif !north && south:
					##room3, pointing south
						#mapgen[l][m].type = RoomTypes.ROOM3
						#mapgen[l][m].angle = 0
						#room3_amount += 1
					#else:
					##horizontal room2
						#var room_angle: Array[float] = [90, 270]
						#mapgen[l][m].type = RoomTypes.ROOM2;
						#mapgen[l][m].angle = room_angle[rng.randi_range(0, 1)]
						#room2_amount += 1
				#elif north:
					#if east:
					##room2c, north-east
						#mapgen[l][m].type = RoomTypes.ROOM2C;
						#mapgen[l][m].angle = 90;
						#room2c_amount += 1
					#elif west:
					##room2c, north-west
						#mapgen[l][m].type = RoomTypes.ROOM2C;
						#mapgen[l][m].angle = 180;
						#room2c_amount += 1
					#else:
					##room1, north
						#mapgen[l][m].type = RoomTypes.ROOM1;
						#mapgen[l][m].angle = 180;
						#room1_amount += 1
				#elif south:
					#if east:
					##room2c, south-east
						#mapgen[l][m].type = RoomTypes.ROOM2C;
						#mapgen[l][m].angle = 0;
						#room2c_amount += 1
					#elif west:
					##room2c, south-west
						#mapgen[l][m].type = RoomTypes.ROOM2C;
						#mapgen[l][m].angle = 270;
						#room2c_amount += 1
					#else:
					##room1, south
						#mapgen[l][m].type = RoomTypes.ROOM1;
						#mapgen[l][m].angle = 0;
						#room1_amount += 1
				#elif east:
					##room1, east
					#mapgen[l][m].type = RoomTypes.ROOM1;
					#mapgen[l][m].angle = 90;
					#room1_amount += 1
				#else:
					##room1, west
					#mapgen[l][m].type = RoomTypes.ROOM1
					#mapgen[l][m].angle = 270
					#room1_amount += 1

# Called when the node enters the scene tree for the first time.
func _ready():
	if rng_seed != -1:
		rng.seed = rng_seed
	generate_zone()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
