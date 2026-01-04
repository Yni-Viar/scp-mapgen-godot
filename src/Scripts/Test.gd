extends Control

var forward_pressed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if DisplayServer.is_touchscreen_available():
		$CameraForward.show()
	else:
		$CameraForward.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_seed_text_changed(new_text):
	if new_text != "":
		get_parent().get_node("FacilityGenerator").rng_seed = hash(new_text)
	else:
		get_parent().get_node("FacilityGenerator").rng_seed = -1


func _on_generate_pressed():
	get_parent().get_node("FacilityGenerator").clear()
	get_parent().get_node("FacilityGenerator").generate_rooms()


func _on_double_room_toggled(toggled_on: bool) -> void:
	get_parent().get_node("FacilityGenerator").double_room_support = toggled_on


func _on_room_pack_button_pressed() -> void:
	if OS.get_name() == "Android":
		OS.request_permission("android.permissions.MANAGE_EXTERNAL_STORAGE")
	get_parent().get_node("SetRoomPack/FileDialog").show()


func _on_room_scale_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		get_parent().get_node("FacilityGenerator").grid_size = float(new_text)


func _on_save_result_pressed() -> void:
	if OS.get_name() == "Android":
		OS.request_permission("android.permissions.WRITE_EXTERNAL_STORAGE")
	get_parent().get_node("RoomSaver/FileDialog").show()


func _on_zone_size_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		get_parent().get_node("FacilityGenerator").zone_size = int(new_text)


func _on_door_toggled(toggled_on: bool) -> void:
	get_parent().get_node("FacilityGenerator").enable_door_generation = toggled_on




func _on_enable_lighting_toggled(toggled_on: bool) -> void:
	if toggled_on:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
	else:
		get_viewport().debug_draw = Viewport.DEBUG_DRAW_UNSHADED


func _on_enable_checkpoints_toggled(toggled_on: bool) -> void:
	get_parent().get_node("FacilityGenerator").checkpoints_enabled = toggled_on


func _on_hints_toggled(toggled_on: bool) -> void:
	$Label.visible = toggled_on


func _on_camera_forward_button_down() -> void:
	get_parent().get_node("Camera3D")._w = true


func _on_camera_forward_button_up() -> void:
	get_parent().get_node("Camera3D")._w = false


func _on_test_semi_infinite_mapgen_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/InfinityGen.tscn")
