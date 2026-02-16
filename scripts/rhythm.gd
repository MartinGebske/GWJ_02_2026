extends Node


@export var selected_tack = 0
@export var tracks : Array[AudioStream]

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	set_audio_track(selected_tack)

func set_audio_track(track: int) -> void:
	audio_stream_player.stream = tracks[track]
	audio_stream_player.play()
