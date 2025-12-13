extends RigidBody2D


@export var hp := 50


@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_player_enemy_hit(dmg) -> void:
	anim_sprite.play("hurt")
	take_damage(dmg)

func take_damage(dmg) -> void:
	hp -= dmg
	print(hp)
	if hp <= 0:
		die()

func die() -> void:
	print("I died.")
	queue_free()


func _on_animation_finished() -> void:
	if anim_sprite.animation == "hurt":
		anim_sprite.play("idle")
