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
