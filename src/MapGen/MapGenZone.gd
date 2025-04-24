@icon("res://MapGen/icons/MapGenResource.svg")
extends Resource
class_name MapGenZone

## Rooms with one exit
@export var endrooms: Array[MapGenRoom]
## Single rooms with one exit
@export var endrooms_single: Array[MapGenRoom] = []
## Single large rooms with one exit
@export var endrooms_single_large: Array[MapGenRoom] = []
## Rooms with two exits, straight
@export var hallways: Array[MapGenRoom]
## Single rooms with two exits, straight
@export var hallways_single: Array[MapGenRoom] = []
## Checkpoint rooms (MapGen v8 new feature)
@export var checkpoint_hallway: Array[MapGenRoom] = []
## Single large rooms with two exits, straight
@export var hallways_single_large: Array[MapGenRoom] = []
## Rooms with two exits, corner
@export var corners: Array[MapGenRoom]
## Single rooms with two exits, corner
@export var corners_single: Array[MapGenRoom] = []
## Single large rooms with two exits, corner
@export var corners_single_large: Array[MapGenRoom] = []
## Rooms with three exits
@export var trooms: Array[MapGenRoom]
## Single rooms with three exits
@export var trooms_single: Array[MapGenRoom] = []
## Single large rooms with three exits
@export var trooms_single_large: Array[MapGenRoom] = []
## Rooms with four exits
@export var crossrooms: Array[MapGenRoom]
## Single rooms with four exits
@export var crossrooms_single: Array[MapGenRoom] = []
## Door hallways
@export var door_frames: Array[PackedScene]
## Checkpoint doors (MapGen v8 new feature)
@export var checkpoint_door_frames: Array[PackedScene]

func _init(p_endrooms: Array[MapGenRoom] = [], p_hallways: Array[MapGenRoom] = [], p_corners: Array[MapGenRoom] = [],
p_trooms: Array[MapGenRoom] = [], p_crossrooms: Array[MapGenRoom] = [], p_door_frames: Array[PackedScene] = []):
	endrooms = p_endrooms
	hallways = p_hallways
	corners = p_corners
	trooms = p_trooms
	crossrooms = p_crossrooms
	door_frames = p_door_frames
