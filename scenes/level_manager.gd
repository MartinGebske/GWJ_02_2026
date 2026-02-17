extends Node

var level_number = 0
var _active_game = false
var goal

@export var level = 0

var music: Node
var color_palette: BarColorPalette
var current_palette: BarColorPalette

var current_palette_index: int = 0

func _ready() -> void:
	call_deferred("_initialize_level")

func setup_level(_level: int) -> void:
	if music:
		music.set_audio_track(_level)

	if color_palette == null:
		push_error("ColorPalette not found!")
		return

	current_palette = color_palette
	var palette_count = BarColorPalette.PaletteType.size()
	current_palette.palette_type = randi() % palette_count

func is_active_game() -> bool:
	return _active_game

func set_active_game(value: bool) -> void:
	_active_game = value
	print("Game start:", value)

func get_bar_color(bar_index: int, total_bars: int) -> Color:
	if current_palette == null:
		return Color.WHITE
	return current_palette.get_color(bar_index, total_bars)

func pick_random_color(color_enum) -> int:
	var enum_size = color_enum.size()
	return randi() % enum_size

func _on_player_in_goal() -> void:
	print("Player in Goal")
	#next_level()

func _initialize_level():
	await get_tree().process_frame

	music = get_tree().get_first_node_in_group("music")
	color_palette = get_tree().get_first_node_in_group("color_palette") as BarColorPalette
	goal = get_tree().get_first_node_in_group("goal")

	if goal:
		goal.connect("player_in_goal", _on_player_in_goal)

	setup_level(level)
	# NICHT direkt starten – wird vom Spieler beim ersten Sprung getriggert

func restart_level():
	print("Restarting Level: ", level)

	set_active_game(false)
	if music:
		music.set_audio_track(level)

	get_tree().call_group("level_reset", "on_level_reset")
	set_active_game(true)

func next_level():
	level += 1
	var track_index = level % 4
	print("Next Level: ", level, " Track: ", track_index)

	setup_level(track_index)
	get_tree().call_group("spectrum", "set_bar_count", get_bar_count_for_level())

func get_bar_count_for_level() -> int:
	return clamp(8 + level * 4, 8, 64)

func reset_run():
	print("Run Reset")
	set_active_game(false)
	get_tree().call_group("run_reset", "on_run_reset")
