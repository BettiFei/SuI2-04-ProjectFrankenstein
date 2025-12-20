extends CharacterBody2D


@export var player : CharacterBody2D

@export var hp := 50
@export var movement_speed := 50.0
@export var attack_dmg := 20
@export var attack_start_frame := 4
@export var attack_end_frame := 6
@export var attack_cooldown_time := 0.8
@export var invulnerable_while_attacking := false
@export var trigger_distance := 200.0
@export var attack_range := 40.0
@export var staggered_time := 0.2
@export var gravity := 1200.0


enum EnemyState {
	IDLE,
	CHASE,
	RETURN,
	ATTACK,
	HURT,
	DIE,
}

const HURT_COLOR := Color("eb402f")
const BASE_COLOR := Color(1, 1, 1, 1)
const MAX_VERTICAL_DETECTION := 32.0

var active_state := EnemyState.IDLE
var distance_from_player : float
var starting_position : Vector2
var movement_target : Vector2 # position of target (e.g., player, starting_pos)

var can_attack := true
var staggered := false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var enemy_hitbox: Area2D = $EnemyHitbox
@onready var attack_collider: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var stagger_timer: Timer = $StaggerTimer
@onready var edge_check: RayCast2D = $EdgeCheck



func _ready() -> void:
	switch_state(EnemyState.IDLE)
	starting_position = global_position
	attack_collider.set_deferred("disabled", true)
	attack_cooldown.wait_time = attack_cooldown_time
	stagger_timer.wait_time = staggered_time
	#get_horizontal_distance_from_player()
	#print(distance_from_player)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	get_horizontal_distance_from_player()
	process_state(delta)
	move_and_slide()


# -- HANDLING STATES --

func switch_state(new_state : EnemyState) -> void:
	var previous_state = active_state
	
	if active_state == new_state:
		return
	
	if active_state == EnemyState.HURT and new_state != EnemyState.HURT:
		anim_sprite.modulate = BASE_COLOR
	
	if active_state == EnemyState.ATTACK:
		attack_collider.set_deferred("disabled", true)
	
	active_state = new_state
	
	match active_state:
		
		EnemyState.IDLE:
			anim_sprite.play("idle")
			velocity.x = 0
			
		EnemyState.CHASE:
			anim_sprite.play("move")
			
		EnemyState.RETURN:
			print("Switched to RETURN state.")
			
		EnemyState.ATTACK:
			if not can_attack:
				switch_state(previous_state)
				return
			#await get_tree().create_timer(0.5).timeout
			anim_sprite.play("attack")
		
		EnemyState.HURT:
			anim_sprite.modulate = HURT_COLOR
			print("Enemy hit. Enemy hp now at: ", str(hp))
			anim_sprite.play("hurt")
			staggered = true
			stagger_timer.start()
			
		EnemyState.DIE:
			print("Enemy dead.")
			anim_sprite.play("die")

func process_state(delta: float) -> void:
	match active_state:
		
		EnemyState.IDLE:
			if distance_from_player <= trigger_distance and is_player_on_same_level():
				if can_attack or distance_from_player > attack_range:
					switch_state(EnemyState.CHASE)
				
		EnemyState.CHASE:
			movement_target = player.global_position
			handle_movement()
			if distance_from_player <= attack_range and is_player_on_same_level():
				if can_attack:
					switch_state(EnemyState.ATTACK)
				else:
					switch_state(EnemyState.IDLE)
			elif distance_from_player > trigger_distance and absf(global_position.x - starting_position.x) > 2.0:
				switch_state(EnemyState.RETURN)
				
		EnemyState.RETURN:
			movement_target = starting_position
			handle_movement()
			if absf(global_position.x - starting_position.x) < 2.0:
				switch_state(EnemyState.IDLE)
			elif distance_from_player <= trigger_distance:
				switch_state(EnemyState.CHASE)
				
		EnemyState.ATTACK:
			velocity.x = 0
			if not is_player_on_same_level():
				switch_state(EnemyState.IDLE)
			elif distance_from_player > attack_range:
				switch_state(EnemyState.CHASE)
			elif distance_from_player > trigger_distance:
				switch_state(EnemyState.RETURN)
				
		EnemyState.HURT:
			velocity.x = 0
			if not staggered:
				switch_state(EnemyState.IDLE)
		
		EnemyState.DIE:
			velocity.x = 0


# -- SUPPORTING FUNCTIONS --

func get_horizontal_distance_from_player():
	if player == null:
		return
	distance_from_player = absf(player.global_position.x - global_position.x)
	return distance_from_player

func get_vertical_distance_from_player() -> float:
	return absf(player.global_position.y - global_position.y)

func is_player_on_same_level() -> bool:
	return get_vertical_distance_from_player() <= MAX_VERTICAL_DETECTION

func get_direction_to_target(target : Vector2) -> float:
	if target.x > global_position.x:
		return 1.0
	else:
		return -1.0

func set_facing_direction(direction) -> void:
	if direction:
		anim_sprite.flip_h = direction < 0
		edge_check.position.x = direction * absf(edge_check.position.x)
		edge_check.target_position.x = direction * absf(edge_check.target_position.x)
		attack_collider.position.x = direction * absf(attack_collider.position.x)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement():
	var direction := get_direction_to_target(movement_target)
	set_facing_direction(direction)
	
	if is_on_floor() and not edge_check.is_colliding():
		velocity.x = 0
		return
	
	velocity.x = direction * movement_speed
	#move_and_slide()

func take_damage(dmg):
	if active_state == EnemyState.ATTACK and invulnerable_while_attacking:
		return
	
	hp -= dmg
	if hp > 0:
		switch_state(EnemyState.HURT)
	elif hp <= 0:
		switch_state(EnemyState.DIE)


# -- HANDLING SIGNALS --

func _on_attack_cooldown_timeout() -> void:
	can_attack = true

func _on_attack_hitbox_body_entered(body: Node2D) -> void: # have I hit the player?
	if body.is_in_group("player"):
		Globals.player_hit.emit(attack_dmg)
		can_attack = false
		attack_cooldown.start()

func _on_animated_sprite_frame_changed() -> void:
	if active_state != EnemyState.ATTACK:
		return
	
	if anim_sprite.frame == attack_start_frame:
		attack_collider.set_deferred("disabled", false)
	elif anim_sprite.frame == attack_end_frame:
		attack_collider.set_deferred("disabled", true)

func _on_animated_sprite_animation_finished() -> void:
	if anim_sprite.animation == "attack" and active_state == EnemyState.ATTACK:
		switch_state(EnemyState.IDLE)
	elif anim_sprite.animation == "die" and active_state == EnemyState.DIE:
		queue_free()

func _on_enemy_hitbox_area_entered(area: Area2D) -> void: # has the player hit me?
	if area.is_in_group("player_attack"):
		if area.is_in_group("light_attack"):
			take_damage(player.light_attack_damage)
		elif area.is_in_group("heavy_attack"):
			take_damage(player.heavy_attack_damage)

func _on_stagger_timer_timeout() -> void:
	staggered = false
