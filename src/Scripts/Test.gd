extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_seed_text_changed(new_text):
	if new_text != "":
		get_parent().get_node("FacilityGenerator").rng_seed = int(new_text)
	else:
		get_parent().get_node("FacilityGenerator").rng_seed = -1


func _on_generate_pressed():
	get_parent().get_node("FacilityGenerator").clear()
	get_parent().get_node("FacilityGenerator").prepare_generation()
