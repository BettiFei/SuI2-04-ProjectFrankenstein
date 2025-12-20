extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.player_died.emit()
		#Engine.time_scale = 0.5
		#await get_tree().create_timer(0.5).timeout
		#get_tree().reload_current_scene()
