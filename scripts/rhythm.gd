extends Node

@export var selected_track: int = -1
@export var tracks: Array[AudioStream]

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

func _ready() -> void:
	pass

func set_audio_track(track: int) -> void:
	if track == selected_track:
		return  # verhindert doppelte Starts

	if tracks.is_empty():
		push_error("No audio tracks assigned!")
		return

	if track < 0 or track >= tracks.size():
		push_error("Track index out of range: " + str(track))
		return

	if audio_stream_player == null:
		push_error("AudioStreamPlayer not found!")
		return

	selected_track = track
	audio_stream_player.stream = tracks[track]

	if audio_stream_player.stream:
		print("Audio length: ", audio_stream_player.stream.get_length())
		audio_stream_player.play()
	else:
		push_error("Selected track is null!")
