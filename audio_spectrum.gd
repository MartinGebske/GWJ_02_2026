extends Node3D

const BAR_COUNT: int = 32 # minimum is 8
const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

var cubes: Array[MeshInstance3D] = []

var spectrum = AudioEffectSpectrumAnalyzerInstance
var heights: Array[Height] = []
var bar_width: float = 0.0 # perhaps this is my bar height...

@onready var cube: MeshInstance3D = $cube


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	for i in BAR_COUNT:
		heights.append(Height.new())
		var new_cube = cube.duplicate()  # Klone den Cube
		new_cube.position.x = i * 1.2  # Positioniere nebeneinander mit Abstand
		new_cube.position.z = 0 # Alle auf die selbe Z achse
		add_child(new_cube)  # Füge zur Szene hinzu
		cubes.append(new_cube)  # Speichere im Array
		cube.queue_free()


func _process(_delta: float) -> void:
	_update_spectrum_data()
	display_something()

func display_something() -> void:
	for i in BAR_COUNT:
		#var l_color = Color.from_hsv((BAR_COUNT * 0.6 + i * 0.5) / BAR_COUNT, 0.5, 0.6)
		# Rainbow:
		var l_color = Color.from_hsv(float(i) / BAR_COUNT, 0.9, 0.8)
		cubes[i].scale.y = heights[i].actual * 4 # TODO: Magic number Setze die Höhe für jeden Cube
		cubes[i].position.y = cubes[i].scale.y / 2
		cubes[i].material_override = StandardMaterial3D.new()
		cubes[i].material_override.albedo_color = l_color  # Farbe zuweisen

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
	bar_width = cube.scale.x / BAR_COUNT # 1000 pro falsch



class Height:
	var high: float
	var low: float
	var actual: float
