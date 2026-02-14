extends Area3D

@export var respawn_position = Vector3()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.position = respawn_position
		print("ist gefallen!")
