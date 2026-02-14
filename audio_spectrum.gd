extends Node3D

const BAR_COUNT: int = 32 # minimum is 8
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

var spectrum = AudioEffectSpectrumAnalyzerInstance
var heights: Array[Height] = []
var cubes: Array = []

var bar_scene: PackedScene = preload("res://scenes/bar.tscn")

@onready var cube: MeshInstance3D = $cube


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	for i in BAR_COUNT:
		heights.append(Height.new())
		var new_bar = bar_scene.instantiate()
		new_bar.position.x = i * 5.0  # Positioniere nebeneinander mit Abstand
		new_bar.scale.x = 1.5
		new_bar.scale.z = 1.5
		add_child(new_bar)
		new_bar.position.z = 0 # Alle auf die selbe Z achse
		cubes.append(new_bar)

		cube.queue_free()


func _process(_delta: float) -> void:
	_update_spectrum_data()
	display_something()

func display_something() -> void:
	for i in BAR_COUNT:
		var hue = float(i) / float(BAR_COUNT - 1)
		var l_color = Color.from_hsv(hue, 1.0, 1.0)

		cubes[i].scale.y = max(heights[i].actual * 10, 0.01) # TODO: Magic number Setze die Höhe für jeden Cube
		cubes[i].position.y = cubes[i].scale.y / 2

		var mesh_instance = cubes[i].get_node("MeshInstance3D")
		var material = StandardMaterial3D.new()
		material.albedo_color = l_color
		mesh_instance.material_override = material


func _update_spectrum_data() -> void:
	var l_prev_hz: float = 0.0
	for i: int in BAR_COUNT:
		var l_hz: float = (i+1) * FREQ_MAX / BAR_COUNT
		var l_magnitude: float = spectrum.get_magnitude_for_frequency_range(l_prev_hz, l_hz).length()
		var l_energy: float = clampf((MIN_DB + linear_to_db(l_magnitude)) / MIN_DB, 0, 1)

		heights[i].high = max(heights[i].high, l_energy)
		heights[i].low = lerp(heights[i].low, l_energy, 0.1)
		heights[i].actual = lerp(heights[i].low, heights[i].high, 0.1)

		l_prev_hz = l_hz

func _on_resized() -> void:
	pass
	#bar_width = cube.scale.x / BAR_COUNT # 1000 pro falsch



class Height:
	var high: float
	var low: float
	var actual: float
