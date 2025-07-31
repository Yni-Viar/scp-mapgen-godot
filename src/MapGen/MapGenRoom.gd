@icon("res://MapGen/icons/MapGenRoom.svg")
extends Resource
class_name MapGenRoom

@export var name: String
@export var prefab: PackedScene
@export var icon_0_degrees: Texture2D
@export var icon_90_degrees: Texture2D
@export var icon_180_degrees: Texture2D
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
@export_group("Double rooms")
## Which room can be connected with this room.
@export var double_room_ids: Array[int] = []
