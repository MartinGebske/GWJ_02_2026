extends Area3D

signal player_fell

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_fell.emit()
