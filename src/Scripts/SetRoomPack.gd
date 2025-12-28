extends Node

const CONVERSION_ALIASES: Dictionary[String, String] = {
	"endrooms": "Room1",
	"endrooms_single": "Room1Single",
	"endrooms_single_large": "Room1SingleLarge",
	"hallways": "Room2",
	"hallways_single": "Room2Single",
	"hallways_single_large": "Room2SingleLarge",
	"corners": "Room2c",
	"corners_single": "Room2cSingle",
	"corners_single_large": "Room2cSingleLarge",
	"trooms": "Room3",
	"trooms_single": "Room3Single",
	"trooms_single_large": "Room3SingleLarge",
	"crossrooms": "Room4",
	"crossrooms_single": "Room4Single"
}

var roompack_temp: DirAccess = DirAccess.create_temp("roompack_temp")
var roompack_packedscenes: DirAccess = DirAccess.create_temp("roompack_packedscenes")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if roompack_temp == null || roompack_packedscenes == null:
		OS.alert("Loading room packs is not supported on your device.")
		get_parent().get_node("UI/VBoxContainer/RoomPackButton").hide()
	elif OS.get_name() == "Android":
		$FileDialog.use_native_dialog = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_file_dialog_file_selected(path: String) -> void:
	# Create temp folders
	#if !DirAccess.dir_exists_absolute("user://roompack_temp/"):
		#var temp: DirAccess = DirAccess.open("user://")
		#temp.make_dir("roompack_temp")
	#if !DirAccess.dir_exists_absolute("user://roompack_packedscenes/"):
		#var temp: DirAccess = DirAccess.open("user://")
		#temp.make_dir("roompack_packedscenes")
	var current_index: int = roompack_temp.get_directories().size() #DirAccess.get_directories_at("user://roompack_temp/").size()
	#if !DirAccess.dir_exists_absolute("user://roompack_temp/" + str(current_index) + "/"):
		#var temp: DirAccess = DirAccess.open("user://roompack_temp/")
		#temp.make_dir(str(current_index))
	if !roompack_temp.dir_exists(str(current_index)):
		roompack_temp.make_dir(str(current_index))
	# Extract all files from zip to first temp folder
	extract_all_from_zip(path, roompack_temp.get_current_dir() + "/" + str(current_index))
	var zone: MapGenZone = MapGenZone.new()
	for alias in CONVERSION_ALIASES:
		# create array for room type 
		var array_for_zone: Array[MapGenRoom] = []
		if DirAccess.dir_exists_absolute(roompack_temp.get_current_dir() + "/" + str(current_index) + "/" + CONVERSION_ALIASES[alias] + "/"):
			for room in DirAccess.get_files_at(roompack_temp.get_current_dir() + "/" + str(current_index) + "/" + CONVERSION_ALIASES[alias] + "/"):
				var mapgenroom: MapGenRoom = MapGenRoom.new()
				mapgenroom.gltf_path = roompack_temp.get_current_dir() + "/" + str(current_index) + "/" + CONVERSION_ALIASES[alias] + "/" + room
				array_for_zone.append(mapgenroom)
		# Set room type to created array
		zone.set(alias, array_for_zone)
	# Pre defined values
	zone.double_rooms = [
		[load("res://MapGen/Resources/EvacuationShelter/room2d_test2.tres"), load("res://MapGen/Resources/EvacuationShelter/room2d_test1.tres")],
		[load("res://MapGen/Resources/EvacuationShelter/room3d_test.tres"), load("res://MapGen/Resources/EvacuationShelter/room2d_test1.tres")]
	]
	zone.door_frames = [load("res://Assets/Doors/door.tscn"), load("res://Assets/Doors/door_alt.tscn")]
	zone.checkpoint_door_frames = [load("res://Assets/Doors/doorcheckpoint.tscn")]
	var result_array: Array[MapGenZone] = [zone]
	get_parent().get_node("FacilityGenerator").rooms = result_array

# Extract all files from a ZIP archive, preserving the directories within.
# This acts like the "Extract all" functionality from most archive managers.
func extract_all_from_zip(path: String, extraction_path: String):
	var reader = ZIPReader.new()
	reader.open(path)

	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	var root_dir = DirAccess.open(extraction_path)

	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)
