extends Resource
class_name MapGenRoom

@export var name: String
#@export var shape: MapGenGlobal.RoomTypes = MapGenGlobal.RoomTypes.ROOM1
#@export var large: bool = false
#@export var necessary: bool = false
#@export var single: bool = false
@export var prefab: PackedScene
#@export var exit: bool = false
@export_range(1, 100) var spawn_chance: float = 20
#@export var astar_travel_cost: int = 2
