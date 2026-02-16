extends Node3D
class_name AudioSpectrum

const FREQ_MAX: float = 11050.0
const MIN_DB: int = 60

@export var player_offset = 0.5
@export_category("Levelcreation")
@export var bar_count: int = 32
@export var smoothness: float = 0.5
@export_category("Rhythm")
@export var beat_pulse_duration: float = 0.15
@export var beats_to_disappear: int = 4 # 4 Beats: 100 -> 75 -> 50 -> 25 -> 0
@export var fade_lerp_speed: float = 12.0 # Wie schnell der Slide passiert
@export_category("Player Movement")
@export var max_z_offset: float = 4.0
@export var max_jump_distance: float = 6.0
@export_category("Goalposition")
@export var goal_scene: PackedScene
@export var goal_distance: float = 6.0 # Abstand nach letzter Bar
@export var goal_height_offset: float = 0.0

var spectrum = AudioEffectSpectrumAnalyzerInstance
var heights: Array[Height] = []
var bars: Array = []

# CLEAN FADE SYSTEM
var current_fading_bar: int = 0
var fade_values: Array[float] = []        # Current (smooth)
var target_fade_values: Array[float] = [] # Target (beat steps)
var beat_steps: Array[int] = []
var fading_flags: Array[bool] = []

var beat_pulse_time: float = 0.0
var active_game = false

var bar_scene: PackedScene = preload("res://scenes/bar.tscn")
@onready var color_palette: BarColorPalette = $"../ColorPalette"


func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	create_bars(bar_count)


func _physics_process(delta: float) -> void:
	_update_spectrum_data()
	_update_fade(delta)

	if beat_pulse_time > 0.0:
		beat_pulse_time -= delta

	display_something()


func _update_fade(delta: float) -> void:
	if not active_game:
		return

	for i in range(bars.size()):
		# Smooth slide towards target (100 -> 75 -> 50 -> 25 -> 0)
		fade_values[i] = lerp(fade_values[i], target_fade_values[i], delta * fade_lerp_speed)

		# Disable collision only when actually invisible
		if fade_values[i] <= 0.02 and bars[i]["collision"].disabled == false:
			bars[i]["collision"].set_deferred("disabled", true)


func create_bars(count: int) -> void:
	var previous_z: float = 0.0
	var last_bar: Node3D = null

	for i in range(count):
		heights.append(Height.new())

		var bar: Node3D = bar_scene.instantiate()

		# Clean state init
		fade_values.append(1.0)
		target_fade_values.append(1.0)
		beat_steps.append(0)
		fading_flags.append(false)

		bar.position.x = i * 5.0
		bar.scale = Vector3(3.0, 2.0, 3.0)

		var new_z = calculate_z_position(previous_z, max_z_offset, max_jump_distance, smoothness)
		bar.position.z = new_z
		previous_z = new_z

		add_child(bar)
		last_bar = bar

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

	_spawn_goal_platform(last_bar)


func display_something() -> void:
	for i in range(bars.size()):
		var data = bars[i]

		var height := float(max(heights[i].actual * 10.0, 0.01))
		var color = color_palette.get_color(i, bar_count)

		data.mesh.scale.y = height
		data.collision.position.y = height / 2.0 - player_offset

		var material: ShaderMaterial = data.material
		var pulse = clamp(beat_pulse_time / beat_pulse_duration, 0.0, 1.0)

		material.set_shader_parameter("beat_strength", pulse * 8.0)
		material.set_shader_parameter("color", color)
		material.set_shader_parameter("alpha_fade", fade_values[i])


func _on_rhythm_notifier_beat(current_beat: int) -> void:
	visualize_beat()

	if not active_game:
		return

	# Start fading next bar every 4 beats
	if current_beat % 4 == 0 and current_fading_bar < bars.size():
		fading_flags[current_fading_bar] = true
		beat_steps[current_fading_bar] = 0
		target_fade_values[current_fading_bar] = 1.0
		current_fading_bar += 1

	# Apply beat-step fade (ALL active bars)
	for i in range(bars.size()):
		if not fading_flags[i]:
			continue

		beat_steps[i] += 1

		var step_ratio := float(beat_steps[i]) / beats_to_disappear
		target_fade_values[i] = clamp(1.0 - step_ratio, 0.0, 1.0)


func visualize_beat() -> void:
	beat_pulse_time = beat_pulse_duration


func _on_player_game_start() -> void:
	active_game = true
	current_fading_bar = 0

	# CRITICAL: full reset to prevent instant disappearing
	for i in range(bars.size()):
		fade_values[i] = 1.0
		target_fade_values[i] = 1.0
		beat_steps[i] = 0
		fading_flags[i] = false
		bars[i]["collision"].set_deferred("disabled", false)


func _on_deadzone_player_fell() -> void:
	active_game = false
	current_fading_bar = 0

	# FULL HARD RESET (fixes your main bug)
	for i in range(bars.size()):
		fade_values[i] = 1.0
		target_fade_values[i] = 1.0
		beat_steps[i] = 0
		fading_flags[i] = false
		bars[i]["collision"].set_deferred("disabled", false)


func _update_spectrum_data() -> void:
	var l_prev_hz: float = 0.0
	for i in range(bar_count):
		var l_hz: float = (i+1) * FREQ_MAX / bar_count
		var l_magnitude: float = spectrum.get_magnitude_for_frequency_range(l_prev_hz, l_hz).length()
		var l_energy: float = clampf((MIN_DB + linear_to_db(l_magnitude)) / MIN_DB, 0, 1)

		heights[i].high = max(heights[i].high, l_energy)
		heights[i].low = lerp(heights[i].low, l_energy, 0.1)
		heights[i].actual = lerp(heights[i].low, heights[i].high, 0.2)

		l_prev_hz = l_hz


func calculate_z_position(_previous_z: float, _max_z_offset: float, _max_jump_distance: float, _smoothness: float) -> float:
	var target_z = randf_range(-_max_z_offset, _max_z_offset)
	var new_z = lerp(_previous_z, target_z, _smoothness)
	new_z = clamp(new_z, _previous_z - _max_jump_distance, _previous_z + _max_jump_distance)
	return new_z

func _spawn_goal_platform(last_bar: Node3D) -> void:
	if goal_scene == null or last_bar == null:
		return

	var goal: Node3D = goal_scene.instantiate()

	var last_pos: Vector3 = last_bar.global_position

	# Faire, erreichbare Position
	goal.position = Vector3(
		last_pos.x + goal_distance,
		last_pos.y + goal_height_offset,
		last_pos.z + randf_range(-1.5, 1.5)
	)

	# WICHTIG: Eigenes ShaderMaterial erzeugen (wie bei Bars!)
	var mesh: MeshInstance3D = goal.get_node("MeshInstance3D")

	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/hologram.gdshader")
	mesh.material_override = shader_material

	# Jetzt funktioniert Farbe + Glow + Beat garantiert
	shader_material.set_shader_parameter("color", Color(1.0, 0.3, 0.9))
	shader_material.set_shader_parameter("beat_strength", 2.0)
	shader_material.set_shader_parameter("alpha_fade", 1.0)

	add_child(goal)



class Height:
	var high: float
	var low: float
	var actual: float
