extends CharacterBody2D


# -- GENERAL PLAYER VARs AND SIGNALS --

@export var hp := 100
@export var light_attack_damage := 5
@export var heavy_attack_damage := 20


# -- STATE ENUM, CONSTs AND VARs --

enum STATE {
	FALL,
	FLOOR,
	JUMP,
	DOUBLE_JUMP,
	LEDGE_CLIMB,
	LEDGE_JUMP,
	WALL_SLIDE,
	WALL_JUMP,
	DASH,
	ATTACK_LIGHT,
	ATTACK_HEAVY,
}


const FALL_GRAVITY := 1500.0
const FALL_VELOCITY := 500.0
const WALK_VELOCITY := 200.0
const JUMP_VELOCITY := -600.0
const JUMP_DECELERATION := 1500.0
const LEDGE_JUMP_VELOCITY := -500.0
const DOUBLE_JUMP_VELOCITY := -450.0
const WALL_SLIDE_GRAVITY := 300.0
const WALL_SLIDE_VELOCITY := 500.0
const WALL_JUMP_LENGTH := 30.0 # amount of pixels player is forced away from the wall
const WALL_JUMP_VELOCITY := -500.0
const DASH_LENGTH := 100.0
const DASH_VELOCITY := 600.0


@onready var anim_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var player_collider: CollisionShape2D = %PlayerCollider
@onready var ledge_climb_ray_cast: RayCast2D = %LedgeClimbRayCast
@onready var ledge_space_ray_cast: RayCast2D = %LedgeSpaceRayCast
@onready var wall_slide_ray_cast: RayCast2D = %WallSlideRayCast
@onready var dash_cooldown: Timer = $DashCooldown
@onready var collision_light_attack: CollisionShape2D = $HitboxLightAttack/CollisionLightAttack
@onready var collision_heavy_attack: CollisionShape2D = $HitboxHeavyAttack/CollisionHeavyAttack
@onready var heavy_attack_cooldown: Timer = $HeavyAttackCooldown


var active_state := STATE.FALL
var can_double_jump := false
var facing_direction := 1.0
var saved_position := Vector2.ZERO
var can_dash := false
var dash_jump_buffer := false


# -- FUNCTIONS --

func _ready() -> void:
	switch_state(active_state) # properly start game with correct state
	ledge_climb_ray_cast.add_exception(self) # prevent raycast from detecting player's own coll. shape
	#print("ledge_climb_offset: " + str(ledge_climb_offset()))
	collision_light_attack.disabled = true
	collision_heavy_attack.disabled = true
	Globals.connect("player_hit", take_damage)

func _physics_process(delta: float) -> void:
	process_state(delta)
	move_and_slide()


# -- FUNCTIONS HANDLING BEHAVIOUR --

func take_damage(dmg) -> void:
	print("Ouch.")
	hp -= dmg
	print("Player HP at ", str(hp))


# -- FUNCTIONS HANDLING STATES --

# Triggered upon input or when condition is met (e.g., if player is not on floor):
func switch_state(new_state: STATE) -> void:
	var previous_state := active_state
	active_state = new_state
	
	# Set state-specific things that only need to run once when entering a new state:
	match active_state:
		STATE.FALL:
			#if previous_state == STATE.DOUBLE_JUMP:
				#await get_tree().create_timer(0.1).timeout
			anim_sprite.play("falling")
			if previous_state == STATE.FLOOR:
				coyote_timer.start()
		
		STATE.FLOOR:
			can_double_jump = true
			can_dash = true
		
		STATE.JUMP:
			anim_sprite.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			
		STATE.DOUBLE_JUMP:
			anim_sprite.play("air_spin")
			velocity.y = DOUBLE_JUMP_VELOCITY
			can_double_jump = false
			
		STATE.LEDGE_CLIMB:
			anim_sprite.play("ledge_climb")
			velocity = Vector2.ZERO
			global_position.y = ledge_climb_ray_cast.get_collision_point().y # make player face direction of ledge & align position with ledge
			can_double_jump = true
			
		STATE.LEDGE_JUMP:
			anim_sprite.play("air_spin")
			velocity.y = LEDGE_JUMP_VELOCITY
		
		STATE.WALL_SLIDE:
			anim_sprite.play("wall_slide")
			velocity.y = 0
			can_double_jump = true
			can_dash = true
			
		STATE.WALL_JUMP:
			anim_sprite.play("jump")
			velocity.y = WALL_JUMP_VELOCITY
			set_facing_direction(-facing_direction)
			saved_position = position
		
		STATE.DASH:
			if dash_cooldown.time_left > 0:
				active_state = previous_state
				return
			anim_sprite.play("dash")
			velocity.y = 0
			set_facing_direction(signf(Input.get_axis("move_left", "move_right")))
			velocity.x = facing_direction * DASH_VELOCITY
			saved_position = position
			can_dash = previous_state == STATE.FLOOR #or previous_state == STATE.WALL_SLIDE
			dash_jump_buffer = false
		
		STATE.ATTACK_LIGHT:
			collision_light_attack.disabled = false
			anim_sprite.play("attack_light")
			velocity.x = 0
		
		STATE.ATTACK_HEAVY:
			if heavy_attack_cooldown.time_left > 0:
				active_state = previous_state
				return
			collision_heavy_attack.disabled = false
			anim_sprite.play("attack_heavy")
			velocity.x = 0
			heavy_attack_cooldown.start()

# Called every physics frame -> put code here that needs to run every frame while in this state:
func process_state(delta: float) -> void:
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			handle_movement()
			
			#print("is_input_toward_facing: " + str(is_input_toward_facing()))
			#print(is_ledge())
			#print(is_space())
			#print("can_wall_slide: " + str(can_wall_slide()))
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif can_double_jump:
					switch_state(STATE.DOUBLE_JUMP)
			elif is_input_toward_facing() and is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif is_input_toward_facing() and can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
			elif Input.is_action_just_pressed("dash") and can_dash:
				switch_state(STATE.DASH)
		
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
			elif Input.is_action_just_pressed("dash"):
				switch_state(STATE.DASH)
			elif Input.is_action_just_pressed("attack_light"):
				switch_state(STATE.ATTACK_LIGHT)
			elif Input.is_action_just_pressed("attack_heavy"):
				switch_state(STATE.ATTACK_HEAVY)
				
		STATE.JUMP, STATE.DOUBLE_JUMP, STATE.LEDGE_JUMP, STATE.WALL_JUMP:
			velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			if active_state == STATE.WALL_JUMP:
				var distance := absf(position.x - saved_position.x)
				if distance >= WALL_JUMP_LENGTH or can_wall_slide():
					active_state = STATE.JUMP
				else:
					handle_movement(facing_direction)
			
			if active_state != STATE.WALL_JUMP:
				handle_movement()
			
			if Input.is_action_just_pressed("jump") and active_state == STATE.JUMP and can_double_jump:
				switch_state(STATE.DOUBLE_JUMP)
			elif Input.is_action_just_pressed("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("dash") and can_dash:
				switch_state(STATE.DASH)
		
		STATE.LEDGE_CLIMB:
			if not anim_sprite.is_playing():
				anim_sprite.play("idle")
				var offset := ledge_climb_offset()
				offset.x *= facing_direction
				position += offset
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				var progress := inverse_lerp(0, anim_sprite.sprite_frames.get_frame_count("ledge_climb"), anim_sprite.frame)
				var offset := ledge_climb_offset()
				offset.x *= facing_direction * progress
				position += offset
				switch_state(STATE.LEDGE_JUMP)
				
		STATE.WALL_SLIDE:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_VELOCITY, WALL_SLIDE_GRAVITY * delta)
			handle_movement()
			
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif not can_wall_slide():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.WALL_JUMP)
		
		STATE.DASH:
			dash_cooldown.start()
			if is_on_floor():
				coyote_timer.start()
			if Input.is_action_just_pressed("jump"):
				dash_jump_buffer = true
			var distance := absf(position.x - saved_position.x)
			if distance >= DASH_LENGTH or signf(get_last_motion().x) != facing_direction:
				if dash_jump_buffer and coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
				elif is_on_floor():
					switch_state(STATE.FLOOR)
				else:
					switch_state(STATE.FALL)
			elif is_ledge() and is_space():
				switch_state(STATE.LEDGE_CLIMB)
			elif can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
		
		STATE.ATTACK_LIGHT:
			if not anim_sprite.is_playing():
				collision_light_attack.disabled = true
				switch_state(STATE.FLOOR)
			if Input.is_action_just_pressed("attack_heavy"):
				await get_tree().create_timer(0.02).timeout
				switch_state(STATE.ATTACK_HEAVY)
			elif Input.is_action_just_pressed("attack_light"):
				await get_tree().create_timer(0.01).timeout
				switch_state(STATE.ATTACK_LIGHT)
		
		STATE.ATTACK_HEAVY:
			if not anim_sprite.is_playing():
				collision_heavy_attack.disabled = true
				switch_state(STATE.FLOOR)
			if Input.is_action_just_pressed("attack_light"):
					await get_tree().create_timer(0.35).timeout
					switch_state(STATE.ATTACK_LIGHT)



# -- FUNCTIONS SUPPORTING STATES --

func handle_movement(input_direction: float = 0) -> void:
	if input_direction == 0:
		input_direction = Input.get_axis("move_left", "move_right")
	set_facing_direction(input_direction)
	velocity.x = input_direction * WALK_VELOCITY

func set_facing_direction(direction: float) -> void:
	if direction:
		anim_sprite.flip_h = direction < 0
		facing_direction = direction
		ledge_climb_ray_cast.position.x = direction * absf(ledge_climb_ray_cast.position.x)
		ledge_climb_ray_cast.target_position.x = direction * absf(ledge_climb_ray_cast.target_position.x)
		ledge_climb_ray_cast.force_raycast_update()
		wall_slide_ray_cast.position.x = direction * absf(wall_slide_ray_cast.position.x)
		wall_slide_ray_cast.target_position.x = direction * absf(wall_slide_ray_cast.target_position.x)
		wall_slide_ray_cast.force_raycast_update()
		collision_light_attack.position.x = direction * absf(collision_light_attack.position.x)
		collision_heavy_attack.position.x = direction * absf(collision_heavy_attack.position.x)

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
		return Vector2(shape.radius * 2.0, -shape.height * 0.5)
	return Vector2.ZERO

# check if wall slide is possible:
func can_wall_slide() -> bool:
	return is_on_wall_only() and wall_slide_ray_cast.is_colliding()
