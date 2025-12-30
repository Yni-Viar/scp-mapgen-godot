extends Node3D

var player: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if ResourceLoader.exists("res://ResearchZoneLite/RZLite.tres"):
		var zones: Array[MapGenZone] = [load("res://ResearchZoneLite/RZLite.tres")]
		$FacilityGenerator.rooms = zones


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_facility_generator_generated() -> void:
	$StaticPlayer.global_position = Vector3(($FacilityGenerator.zone_size * ($FacilityGenerator.map_size_x + 1)) / 2 * $FacilityGenerator.grid_size, 0, ($FacilityGenerator.zone_size * ($FacilityGenerator.map_size_y + 1)) / 2 * $FacilityGenerator.grid_size)
