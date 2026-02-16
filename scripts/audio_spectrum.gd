extends Node3D

const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

@export var max_z_offset: float = 2.0
@export var max_jump_distance: float = 3.0
@export var smoothness: float = 0.5
@export var bar_count: int = 32 # minimum is 8

@export var player_offset = 0.5

var spectrum = AudioEffectSpectrumAnalyzerInstance
var heights: Array[Height] = []
var bars: Array = []
var fade_values: Array[float] = []
var bar_scene: PackedScene = preload("res://scenes/bar.tscn")

@onready var color_palette: BarColorPalette = $"../ColorPalette"


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	create_bars(bar_count)


func _physics_process(_delta: float) -> void:
	_update_spectrum_data()
	display_something()

func create_bars(count: int) -> void:
	var previous_z: float = 0.0

	for i in range(count):
		heights.append(Height.new())

		var bar: Node3D = bar_scene.instantiate()
		fade_values.append(1.0)
		bar.position.x = i * 5.0
		bar.scale = Vector3(3.0, 2.0, 3.0)

		var new_z = calculate_z_position(previous_z, max_z_offset, max_jump_distance, smoothness)
		bar.position.z = new_z
		previous_z = new_z

		add_child(bar)

		# Cache nodes ONCE
		var mesh: MeshInstance3D = bar.get_node("MeshInstance3D")
		var collision: CollisionShape3D = bar.get_node("CollisionShape3D")

		var shader_material := ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/hologram.gdshader")
		mesh.material_override = shader_material

		bars.append({
			"bar": bar,
			"mesh": mesh,
			"collision": collision,
			"material": shader_material
		})


func display_something() -> void:
	for i in range(bar_count):
		var data = bars[i]

		var height := float(max(heights[i].actual * 10.0, 0.01))
		var color = color_palette.get_color(i, bar_count)

		data.mesh.scale.y = height
		data.collision.position.y = height / 2.0 - player_offset

		#data.material.set_shader_parameter("color", color)
		var material: ShaderMaterial = data.material # oder dein aktueller Zugriff
		var beat = heights[i].actual

		material.set_shader_parameter("color", color)
		material.set_shader_parameter("beat_strength", beat)


func _update_spectrum_data() -> void:
	var l_prev_hz: float = 0.0
	for i: int in bar_count:
		var l_hz: float = (i+1) * FREQ_MAX / bar_count
		var l_magnitude: float = spectrum.get_magnitude_for_frequency_range(l_prev_hz, l_hz).length()
		var l_energy: float = clampf((MIN_DB + linear_to_db(l_magnitude)) / MIN_DB, 0, 1)

		heights[i].actual += randf_range(-1.0, 1.0)
		heights[i].actual = clamp(heights[i].actual, 0, 1)

		heights[i].high = max(heights[i].high, l_energy)
		heights[i].low = lerp(heights[i].low, l_energy, 0.1)
		heights[i].actual = lerp(heights[i].low, heights[i].high, 0.001)

		l_prev_hz = l_hz


func calculate_z_position(_previous_z: float, _max_z_offset: float, _max_jump_distance: float, _smoothness: float) -> float:
	var target_z = randf_range(-_max_z_offset, _max_z_offset)
	# Smooth it out via lerping
	var new_z = lerp(_previous_z, target_z, _smoothness)
	# Way to next bar is clamped:
	new_z = clamp(new_z, _previous_z - _max_jump_distance, _previous_z + _max_jump_distance)
	return new_z

class Height:
	var high: float
	var low: float
	var actual: float
