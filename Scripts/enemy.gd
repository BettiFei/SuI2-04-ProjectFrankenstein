extends RigidBody2D


@export var player : CharacterBody2D

@export var hp := 50
@export var attack_dmg := 20
@export var move_speed := 50.0


@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_range: Area2D = $AttackRange
@onready var attack_hitbox: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_buffer: Timer = $AttackBuffer

var attack_on_cooldown := false
var in_attack_range := false
var has_hit_player := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attack_hitbox.set_deferred("disabled", true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if in_attack_range and not attack_on_cooldown:
		attack()


# -- SIGNAL FUNCTIONS --

func _on_enemy_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		anim_sprite.play("hurt")
		if area.is_in_group("light_attack"):
			take_damage(player.light_attack_damage)
		elif area.is_in_group("heavy_attack"):
			take_damage(player.heavy_attack_damage)
		else:
			print("Couldn't get damage value.")


func _on_player_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("I see the player.")
		# set facing direction towards player
		# start moving towards player


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("I can attack.")
		in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		in_attack_range = false
		attack_hitbox.set_deferred("disabled", true)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not has_hit_player:
		has_hit_player = true
		print("I hit the player.")
		Globals.player_hit.emit(attack_dmg)

func _on_attack_buffer_timeout() -> void:
	attack_on_cooldown = false



func _on_animation_finished() -> void:
	if anim_sprite.animation == "die":
		queue_free()
	#elif anim_sprite.animation == "attack": #and not in_attack_range
		#attack_hitbox.set_deferred("disabled", true)
	else:
		anim_sprite.play("idle")


# -- BEHAVIOUR FUNCTIONS --

func attack() -> void:
	if attack_on_cooldown or not in_attack_range:
		return
	
	has_hit_player = false
	anim_sprite.play("attack")
	attack_on_cooldown = true
	attack_buffer.start()

func take_damage(dmg) -> void:
	hp -= dmg
	print(hp)
	# stagger -> interrupt movement & attacks (while "hurt" is playing?)
	if hp <= 0:
		die()

func die() -> void:
	print("That's .. to much .... i ded.")
	anim_sprite.play("die")

func set_facing_direction() -> void: # turn towards player
	pass
	# get player position
	# turn towards player (flip sprite if necessary)

func handle_movement() -> void:
	pass
	# if no player in sight: idle around
	# if player in sight: move towards player
	# if player in range: attack
