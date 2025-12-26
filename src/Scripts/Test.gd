extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
	get_parent().get_node("SetRoomPack/FileDialog").show()


func _on_room_scale_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		get_parent().get_node("FacilityGenerator").grid_size = float(new_text)
