extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

## Used from Godot Docs
func save_snapshot(path: String):
	# Save a new glTF scene.
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.append_from_scene(get_parent().get_node("FacilityGenerator"), gltf_state_save)
	# The file extension in the output `path` (`.gltf` or `.glb`) determines
	# whether the output uses text or binary format.
	# `GLTFDocument.generate_buffer()` is also available for saving to memory.
	gltf_document_save.write_to_filesystem(gltf_state_save, path)


func _on_file_dialog_file_selected(path: String) -> void:
	save_snapshot(path)
