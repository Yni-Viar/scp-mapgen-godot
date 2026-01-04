extends Label

# Most of this code is third-party code from Godot Engine. 
# Copyright (c) 2014-present Godot Engine contributors.
# Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
# Licensed under MIT License.

#begin Godot Engine code
var fps_history: PackedFloat32Array = []
var current_index: int = 0
var gpu_time: float = 0.0

func _init():
	fps_history.resize(20)
	fps_history.fill(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fps_history[current_index] = RenderingServer.viewport_get_measured_render_time_gpu(get_tree().root.get_viewport_rid())
	current_index = (current_index + 1) % 20
	for i in range(20):
		gpu_time += fps_history[i]
	gpu_time /= 20
	gpu_time = max(0.01, gpu_time)
	#end Godot Engine code
	text = "Real FPS: " + str(Engine.get_frames_per_second()) + "\nGPU FPS: " + str(snapped(1000.0 / gpu_time, 1))
	#begin Godot Engine code
	gpu_time = 0.0
	#end Godot Engine code
