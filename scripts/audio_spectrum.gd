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
var cubes: Array = []

var bar_scene: PackedScene = preload("res://scenes/bar.tscn")

var random: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	random.randomize()
	var previous_z: float = 0.0

	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	for i in bar_count:
		heights.append(Height.new())

		var new_bar = bar_scene.instantiate()
		new_bar.position.x = i * 5.0
		new_bar.scale.x = 3.0
		new_bar.scale.z = 3.0

		var new_z = calculate_z_position(previous_z, max_z_offset,max_jump_distance, smoothness)
		new_bar.position.z = new_z
		previous_z = new_z

		add_child(new_bar)
		cubes.append(new_bar)

		# Create shader material
		var shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/hologram.gdshader")
		var mesh_instance = new_bar.get_node("MeshInstance3D")
		mesh_instance.material_override = shader_material

func _physics_process(_delta: float) -> void:
	_update_spectrum_data()
	display_something()

func display_something() -> void:
	for i in bar_count:
		var hue = float(i) / float(bar_count - 1)
		var l_color = Color.from_hsv(hue, 1.0, 1.0)

		var height := float(max(heights[i].actual * 10.0, 0.01))

		var bar = cubes[i]
		var mesh: MeshInstance3D = bar.get_node("MeshInstance3D")
		var collision: CollisionShape3D = bar.get_node("CollisionShape3D")

		bar.scale = Vector3(3.0, 2.0, 3.0) # Y immer 1 lassen!

		mesh.scale.y = height
		#mesh.scale.y = lerp(mesh.scale.y, height, 0.3)

		collision.position.y = height / 2.0 - player_offset
		#collision.position.y = mesh.scale.y / 2.0 - player_offset

		bar.position.y = 0.0



		var mesh_instance = cubes[i].get_node("MeshInstance3D")
		var material = mesh_instance.material_override
		material.set_shader_parameter("color", l_color)


func _update_spectrum_data() -> void:
	var l_prev_hz: float = 0.0
	for i: int in bar_count:
		var l_hz: float = (i+1) * FREQ_MAX / bar_count
		var l_magnitude: float = spectrum.get_magnitude_for_frequency_range(l_prev_hz, l_hz).length()
		var l_energy: float = clampf((MIN_DB + linear_to_db(l_magnitude)) / MIN_DB, 0, 1)

		heights[i].high = max(heights[i].high, l_energy)
		heights[i].low = lerp(heights[i].low, l_energy, 0.1)
		heights[i].actual = lerp(heights[i].low, heights[i].high, 0.1)

		l_prev_hz = l_hz

func _on_resized() -> void:
	pass
	#bar_width = cube.scale.x / BAR_COUNT # 1000 pro falsch

func calculate_z_position(previous_z: float, max_z_offset: float, max_jump_distance: float, smoothness: float) -> float:
	var target_z = randf_range(-max_z_offset, max_z_offset)
	# Smooth it out via lerping
	var new_z = lerp(previous_z, target_z, smoothness)
	# Way to next bar is clamped:
	new_z = clamp(new_z, previous_z - max_jump_distance, previous_z + max_jump_distance)
	return new_z

class Height:
	var high: float
	var low: float
	var actual: float
