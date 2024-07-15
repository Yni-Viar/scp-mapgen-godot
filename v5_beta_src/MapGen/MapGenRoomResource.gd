extends Resource
class_name MapGenZone

@export var endrooms: Array[MapGenRoom]
@export var endrooms_single: Array[MapGenRoom] = []
@export var hallways: Array[MapGenRoom]
@export var hallways_single: Array[MapGenRoom] = []
@export var corners: Array[MapGenRoom]
@export var corners_single: Array[MapGenRoom] = []
@export var trooms: Array[MapGenRoom]
@export var trooms_single: Array[MapGenRoom] = []
@export var crossrooms: Array[MapGenRoom]
@export var crossrooms_single: Array[MapGenRoom] = []

func _init(p_endrooms: Array[MapGenRoom] = [], p_hallways: Array[MapGenRoom] = [], p_corners: Array[MapGenRoom] = [],
p_trooms: Array[MapGenRoom] = [], p_crossrooms: Array[MapGenRoom] = []):
	endrooms = p_endrooms
	hallways = p_hallways
	corners = p_corners
	trooms = p_trooms
	crossrooms = p_crossrooms
