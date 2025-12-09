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
const JUMP_VELOCITY := -600.0
const JUMP_DECELERATION := 1500.0
const DOUBLE_JUMP_VELOCITY := -450.0

@onready var anim_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer

var active_state := STATE.FALL
var can_double_jump := false

func _ready() -> void:
	switch_state(active_state) # properly start game with correct state

func _physics_process(delta: float) -> void:
	process_state(delta)
	move_and_slide()

# Triggered upon input or when condition is met (e.g., if player is not on floor):
func switch_state(new_state: STATE) -> void:
	var previous_state := active_state
	active_state = new_state
	
	# Set state-specific things that only need to run once when entering a new state:
	match active_state:
		STATE.FALL:
			anim_sprite.play("falling")
			if previous_state == STATE.FLOOR:
				coyote_timer.start()
		
		STATE.FLOOR:
			can_double_jump = true
		
		STATE.JUMP:
			anim_sprite.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			
		STATE.DOUBLE_JUMP:
			anim_sprite.play("jump")
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false

# Called every physics frame -> put code here that needs to run every frame while in this state:
func process_state(delta: float) -> void:
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif can_double_jump:
					switch_state(STATE.DOUBLE_JUMP)
		
		STATE.FLOOR:
			if Input.get_axis("move_left", "move_right"):
				anim_sprite.play("run")
			else:
				anim_sprite.play("idle")
			handle_movement()
			
			if not is_on_floor():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.JUMP)
				
		STATE.JUMP, STATE.DOUBLE_JUMP:
			velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			handle_movement()
			
			if Input.is_action_just_pressed("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)

func handle_movement() -> void:
	var input_direction := Input.get_axis("move_left", "move_right")
	if input_direction < 0:
		anim_sprite.flip_h = true
	elif input_direction > 0:
		anim_sprite.flip_h = false
	velocity.x = input_direction * WALK_VELOCITY
