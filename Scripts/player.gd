extends CharacterBody2D


enum STATE {
	FALL,
	FLOOR,
	JUMP,
	DOUBLE_JUMP,
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
@onready var player_collider: CollisionShape2D = %PlayerCollider
@onready var ledge_climb_ray_cast: RayCast2D = %LedgeClimbRayCast
@onready var ledge_space_ray_cast: RayCast2D = %LedgeSpaceRayCast

var active_state := STATE.FALL
var can_double_jump := false
var facing_direction := 1.0

func _ready() -> void:
	switch_state(active_state) # properly start game with correct state
	ledge_climb_ray_cast.add_exception(self) # prevent raycast from detecting player's own coll. shape

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
			if previous_state == STATE.DOUBLE_JUMP:
				await get_tree().create_timer(0.1).timeout
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
			anim_sprite.play("air_spin")
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			
		#STATE.LEDGE_CLIMB:
			#anim_sprite.play("ledge_climb")
			#velocity = Vector2.ZERO
			#global_position.y = ledge_climb_ray_cast.get_collision_point().y # make player face direction of ledge & align position with ledge
			#can_double_jump = true

# Called every physics frame -> put code here that needs to run every frame while in this state:
func process_state(delta: float) -> void:
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			handle_movement()
			
			#print(is_input_toward_facing())
			#print(is_ledge())
			#print(is_space())
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif can_double_jump:
					switch_state(STATE.DOUBLE_JUMP)
			#elif is_input_toward_facing() and is_ledge() and is_space():
				#switch_state(STATE.LEDGE_CLIMB)
		
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
		
		#STATE.LEDGE_CLIMB:
			#if not anim_sprite.is_playing():
				#anim_sprite.play("idle")
				#var offset := ledge_climb_offset()
				#offset.x *= facing_direction
				#position += offset
				#switch_state(STATE.FLOOR)

func handle_movement() -> void:
	var input_direction := Input.get_axis("move_left", "move_right")
	if input_direction:
		anim_sprite.flip_h = input_direction < 0
		facing_direction = input_direction
		ledge_climb_ray_cast.position.x = input_direction * absf(ledge_climb_ray_cast.position.x)
		ledge_climb_ray_cast.target_position.x = input_direction * absf(ledge_climb_ray_cast.position.x)
		ledge_climb_ray_cast.force_raycast_update()
	velocity.x = input_direction * WALK_VELOCITY

# returns whether or not player is giving input towards a ledge:
func is_input_toward_facing() -> bool:
	return signf(Input.get_axis("move_left", "move_right")) == facing_direction

# returns whether what we are colliding with is a ledge:
func is_ledge() -> bool:
	return is_on_wall_only() and \
	ledge_climb_ray_cast.is_colliding() and \
	ledge_climb_ray_cast.get_collision_normal().is_equal_approx(Vector2.UP)
	
# returns whether there is enough space for player on top of ledge:
func is_space() -> bool:
	ledge_space_ray_cast.global_position = ledge_climb_ray_cast.get_collision_point()
	ledge_space_ray_cast.force_raycast_update()
	return not ledge_space_ray_cast.is_colliding()

# perfectly snap player to top of the ledge:
func ledge_climb_offset() -> Vector2:
	var shape := player_collider.shape
	if shape is CapsuleShape2D:
		return Vector2(shape.radius * 2.0, -shape.height * 0.7)
	return Vector2.ZERO
