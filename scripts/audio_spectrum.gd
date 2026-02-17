extends Node3D
class_name AudioSpectrum

@export var player_offset = 0.5
@export_category("Levelcreation")
@export var bar_count: int = 32
@export var smoothness: float = 0.5
@export_category("Rhythm")
@export var beat_pulse_duration: float = 0.15
@export var beats_to_disappear: int = 4
@export var fade_lerp_speed: float = 12.0
@export_category("Player Movement")
@export var max_z_offset: float = 4.0
@export var max_jump_distance: float = 6.0
@export_category("Goalposition")
@export var goal_scene: PackedScene
@export var goal_distance: float = 6.0
@export var goal_height_offset: float = 0.0

var spectrum = AudioEffectSpectrumAnalyzerInstance
var heights: Array[Height] = []
var bars: Array = []

var current_fading_bar: int = 0
var fade_values: Array[float] = []
var target_fade_values: Array[float] = []
var beat_steps: Array[int] = []
var fading_flags: Array[bool] = []

var beat_pulse_time: float = 0.0
var bar_scene: PackedScene = preload("res://scenes/bar.tscn")

func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	create_bars(bar_count)

	# Player finden und Signal verbinden
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_node.game_start.connect(self, "_on_player_game_start")

func _physics_process(delta: float) -> void:
	_update_spectrum_data()
	if LevelManager.is_active_game():
		_update_fade(delta)
	if beat_pulse_time > 0.0:
		beat_pulse_time -= delta
	display_something()

func _update_fade(delta: float) -> void:
	for i in range(bars.size()):
		fade_values[i] = lerp(fade_values[i], target_fade_values[i], delta * fade_lerp_speed)
		if fade_values[i] <= 0.02 and bars[i]["collision"].disabled == false:
			bars[i]["collision"].set_deferred("disabled", true)

func create_bars(count: int) -> void:
	var previous_z: float = 0.0
	var last_bar: Node3D = null

	for i in range(count):
		heights.append(Height.new())
		var bar: Node3D = bar_scene.instantiate()
		fade_values.append(1.0)
		target_fade_values.append(1.0)
		beat_steps.append(0)
		fading_flags.append(false)
		bar.position.x = i * 5.0
		bar.scale = Vector3(3.0, 2.0, 3.0)
		bar.position.z = calculate_z_position(previous_z, max_z_offset, max_jump_distance, smoothness)
		previous_z = bar.position.z
		add_child(bar)
		last_bar = bar
		var mesh: MeshInstance3D = bar.get_node("MeshInstance3D")
		var collision: CollisionShape3D = bar.get_node("CollisionShape3D")
		var shader_material := ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/hologram.gdshader")
		mesh.material_override = shader_material
		bars.append({"bar": bar, "mesh": mesh, "collision": collision, "material": shader_material})

	_spawn_goal_platform(last_bar)

func display_something() -> void:
	for i in range(bars.size()):
		var data = bars[i]
		var height := float(max(heights[i].actual * 10.0, 0.01))
		var color = LevelManager.get_bar_color(i, bar_count)
		data.mesh.scale.y = height
		data.collision.position.y = height / 2.0 - player_offset
		var material: ShaderMaterial = data.material
		var pulse = clamp(beat_pulse_time / beat_pulse_duration, 0.0, 1.0)
		material.set_shader_parameter("beat_strength", pulse * 8.0)
		material.set_shader_parameter("color", color)
		material.set_shader_parameter("alpha_fade", fade_values[i])

func _on_rhythm_notifier_beat(current_beat: int) -> void:
	visualize_beat()
	if not LevelManager.is_active_game():
		return
	if current_beat % 4 == 0 and current_fading_bar < bars.size():
		fading_flags[current_fading_bar] = true
		beat_steps[current_fading_bar] = 0
		target_fade_values[current_fading_bar] = 1.0
		current_fading_bar += 1
	for i in range(bars.size()):
		if not fading_flags[i]:
			continue
		beat_steps[i] += 1
		var step_ratio := float(beat_steps[i]) / beats_to_disappear
		target_fade_values[i] = clamp(1.0 - step_ratio, 0.0, 1.0)

func visualize_beat() -> void:
	beat_pulse_time = beat_pulse_duration

func _on_player_game_start() -> void:
	LevelManager.set_active_game(true)
	current_fading_bar = 0
	for i in range(bars.size()):
		fade_values[i] = 1.0
		target_fade_values[i] = 1.0
		beat_steps[i] = 0
		fading_flags[i] = false
		bars[i]["collision"].set_deferred("disabled", false)

func on_run_reset() -> void:
	LevelManager.set_active_game(false)
	current_fading_bar = 0
	beat_pulse_time = 0.0
	for i in range(bars.size()):
		fade_values[i] = 1.0
		target_fade_values[i] = 1.0
		beat_steps[i] = 0
		fading_flags[i] = false
		bars[i]["collision"].set_deferred("disabled", false)

func _update_spectrum_data() -> void:
	var l_prev_hz: float = 0.0
	for i in range(bar_count):
		var l_hz: float = (i+1) * 11050.0 / bar_count
		var l_magnitude: float = spectrum.get_magnitude_for_frequency_range(l_prev_hz, l_hz).length()
		var l_energy: float = clampf((60 + linear_to_db(l_magnitude)) / 60, 0, 1)
		heights[i].high = max(heights[i].high, l_energy)
		heights[i].low = lerp(heights[i].low, l_energy, 0.1)
		heights[i].actual = lerp(heights[i].low, heights[i].high, 0.2)
		l_prev_hz = l_hz

func calculate_z_position(_previous_z: float, _max_z_offset: float, _max_jump_distance: float, _smoothness: float) -> float:
	var target_z = randf_range(-_max_z_offset, _max_z_offset)
	var new_z = lerp(_previous_z, target_z, _smoothness)
	return clamp(new_z, _previous_z - _max_jump_distance, _previous_z + _max_jump_distance)

func _spawn_goal_platform(last_bar: Node3D) -> void:
	if goal_scene == null or last_bar == null:
		return
	var goal: Node3D = goal_scene.instantiate()
	var last_pos: Vector3 = last_bar.position
	goal.position = Vector3(last_pos.x + goal_distance, last_pos.y + goal_height_offset, last_pos.z + randf_range(-1.5, 1.5))
	add_child(goal)
	var mesh := goal.find_child("MeshInstance3D", true, false) as MeshInstance3D
	if mesh == null:
		push_warning("Goal MeshInstance3D nicht gefunden!")
		return
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/hologram.gdshader")
	mesh.material_override = shader_material
	shader_material.set_shader_parameter("color", Color(1.0, 0.3, 0.9))
	shader_material.set_shader_parameter("beat_strength", 2.0)
	shader_material.set_shader_parameter("alpha_fade", 1.0)

class Height:
	var high: float
	var low: float
	var actual: float
