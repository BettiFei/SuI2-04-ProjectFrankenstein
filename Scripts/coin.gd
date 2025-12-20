extends Area2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		animation_player.play("pick_up")
		await get_tree().create_timer(0.5).timeout
		Globals.coin_collected.emit()
