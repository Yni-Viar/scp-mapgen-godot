@icon("res://MapGen/icons/MapGenRoom.svg")
extends Resource
class_name MapGenRoom

enum DoubleRoomTypes {NONE, ROOM2D = 2, ROOM2CD = 3, ROOM3D = 4, ROOM4D = 5}

enum DoubleRoomPosition {UP, DOWN, LEFT, RIGHT}

@export var name: String
@export var prefab: PackedScene
## RIGHT for most rooms, room2c RIGHT
@export var icon_0_degrees: Texture2D
## UP for most rooms, room2c DOWN
@export var icon_90_degrees: Texture2D
## LEFT for most rooms, room2c LEFT
@export var icon_180_degrees: Texture2D
## DOWN for most rooms, room2c UP
@export var icon_270_degrees: Texture2D
@export_range(1, 100) var spawn_chance: float = 20
## Added in mapgen v8. The default value, -1 means,
## that any door frame (see MapGenZone door_frames) can be used.
## Otherwise, only specific door frame can be used with this room.
@export var door_type: int = -1
## Ignore spawn chance
## /!\ WARNING!!! If the map is too small, guaranteed rooms may not spawn.
@export var guaranteed_spawn: bool = false
## Added in mapgen v9. Requires "Double room support" to be enabled.
@export_group("Optional properties")
## Exported GLTF path, used when PackedScene is not available
@export var gltf_path: String = ""
@export_group("Double rooms")
@export var double_room_position: DoubleRoomPosition = DoubleRoomPosition.UP
## Room shape for double room generation
@export var double_room_shape: DoubleRoomTypes = DoubleRoomTypes.NONE
