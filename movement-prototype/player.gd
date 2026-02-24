extends CharacterBody2D

const WALK_SPEED = 300.0
const DASH_SPEED = 900.0
const MAX_DASH_DISTANCE = 250.0

enum State { WALK, DASH }
var current_state = State.WALK

var sync_position: Vector2

var dash_direction := Vector2.ZERO
var distance_traveled := 0.0
var last_valid_direction := Vector2.RIGHT


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	sync_position = global_position


func _ready():
	if is_multiplayer_authority():
		position.x = randi_range(50, 550)
		position.y = randi_range(50, 550)


func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	
	if is_multiplayer_authority():
		sync_position = global_position
		
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		
		if input_dir != Vector2.ZERO:
			last_valid_direction = input_dir
		
		if Input.is_action_just_pressed("dash"):
			if current_state == State.WALK:
				trigger_dash.rpc(last_valid_direction, global_position)
			elif current_state == State.DASH:
				cancel_dash.rpc(global_position)
	
	match current_state:
		State.WALK:
			if is_multiplayer_authority():
				velocity = input_dir * WALK_SPEED
				move_and_slide()
			else:
				global_position = global_position.lerp(sync_position, 20 * delta)
		State.DASH:
			velocity = dash_direction * DASH_SPEED
			move_and_slide()
			
			if is_multiplayer_authority():
				var step_distance = DASH_SPEED * delta
				distance_traveled += step_distance
				if distance_traveled >= MAX_DASH_DISTANCE:
						cancel_dash.rpc(global_position)


@rpc("any_peer", "call_local", "reliable")
func trigger_dash(dir: Vector2, pos: Vector2):
	global_position = pos
	dash_direction = dir
	distance_traveled = 0.0
	current_state = State.DASH


@rpc("any_peer", "call_local")
func cancel_dash(pos: Vector2):
	global_position = pos
	current_state = State.WALK
	velocity = Vector2.ZERO
