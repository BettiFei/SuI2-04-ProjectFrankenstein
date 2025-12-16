extends AnimatedSprite2D

@export var attack_hitbox : CollisionShape2D


func _on_frame_changed() -> void:
	if animation == "attack":
		if frame == 4:
			attack_hitbox.set_deferred("disabled", false)
		elif frame == 6:
			attack_hitbox.set_deferred("disabled", true)
