extends CharacterBody2D


@export var player : CharacterBody2D

@export var hp := 50
@export var movement_speed := 50.0
@export var attack_dmg := 20
@export var trigger_distance := 200.0
@export var attack_range := 40.0


enum EnemyState {
	IDLE,
	CHASE,
	RETURN,
	ATTACK,
	HURT,
	DIE,
}

var active_state := EnemyState.IDLE
var distance_from_player
var starting_position
var movement_target

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite



func _ready() -> void:
	switch_state(EnemyState.IDLE)
	starting_position = global_position
	get_distance_from_player()
	print(distance_from_player)

func _physics_process(delta: float) -> void:
	get_distance_from_player()
	process_state(delta)


# -- HANDLING STATES --

func switch_state(new_state : EnemyState) -> void:
	var previous_state = active_state
	
	if active_state == new_state:
		return
	
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
			print("Switched to ATTACK state.")
		
		EnemyState.HURT:
			print("Switched to HURT state.")
			
		EnemyState.DIE:
			print("Switched to DIE state.")

func process_state(delta: float) -> void:
	match active_state:
		
		EnemyState.IDLE:
			if distance_from_player <= trigger_distance:
				switch_state(EnemyState.CHASE)
				
		EnemyState.CHASE:
			movement_target = player.global_position
			handle_movement()
			if distance_from_player <= attack_range:
				switch_state(EnemyState.ATTACK)
			elif distance_from_player > trigger_distance and absf(global_position.x - starting_position.x) > 2.0:
				switch_state(EnemyState.RETURN)
				
		EnemyState.RETURN:
			movement_target = starting_position
			handle_movement()
			if absf(global_position.x - starting_position.x) < 2.0:
				switch_state(EnemyState.IDLE)
				
		EnemyState.ATTACK:
			velocity.x = 0
			anim_sprite.play("attack")
			if distance_from_player > attack_range:
				switch_state(EnemyState.CHASE)
			elif distance_from_player > trigger_distance:
				#return to starting_position
				switch_state(EnemyState.IDLE)
				
		EnemyState.HURT:
			print("Processing HURT state.")
		
		EnemyState.DIE:
			print("Processing DIE state.")


# -- SUPPORTING FUNCTIONS --

func get_distance_from_player():
	if player == null:
		return
	distance_from_player = absf(player.global_position.x - global_position.x)
	return distance_from_player

func get_direction_to_target(target : Vector2) -> float:
	if target.x > global_position.x:
		return 1.0
	else:
		return -1.0

func set_facing_direction(direction) -> void:
	anim_sprite.flip_h = direction < 0

func handle_movement():
	var direction := get_direction_to_target(movement_target)
	set_facing_direction(direction)
	velocity.x = direction * movement_speed
	move_and_slide()
