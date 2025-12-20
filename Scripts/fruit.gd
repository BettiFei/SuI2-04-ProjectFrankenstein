extends Area2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer


@export var heal_amount := 20

func _ready() -> void:
	animation_player.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Globals.fruit_eaten.emit(heal_amount)
		animation_player.play("pick_up")
