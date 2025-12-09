extends CharacterBody2D


enum STATE {
	FALL,
	FLOOR,
	JUMP,
	DOUBLE_JUMP,
	FLOAT,
	LEDGE_CLIMB,
	LEDGE_JUMP,
}

const FALL_GRAVITY := 1500.0
const FALL_VELOCITY := 500.0
const WALK_VELOCITY := 200.0

@onready var anim_sprite: AnimatedSprite2D = %AnimatedSprite2D

var active_state := STATE.FALL

func _ready() -> void:
	switch_state(active_state) # properly start game with correct state

func _physics_process(delta: float) -> void:
	process_state(delta)
	move_and_slide()

# Triggered upon input or when condition is met (e.g., if player is not on floor):
func switch_state(new_state: STATE) -> void:
	active_state = new_state
	
	# Set state-specific things that only need to run once when entering a new state:
	match active_state:
		STATE.FALL:
			anim_sprite.play("falling")

# Called every physics frame -> put code here that needs to run every frame while in this state:
func process_state(delta: float) -> void:
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
		
		STATE.FLOOR:
			if Input.get_axis("move_left", "move_right"):
				anim_sprite.play("run")
			else:
				anim_sprite.play("idle")
			handle_movement()
			
			if not is_on_floor():
				switch_state(STATE.FALL)

func handle_movement() -> void:
	var input_direction := Input.get_axis("move_left", "move_right")
	if input_direction < 0:
		anim_sprite.flip_h = true
	elif input_direction > 0:
		anim_sprite.flip_h = false
	velocity.x = input_direction * WALK_VELOCITY
