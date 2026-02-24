extends CharacterBody2D

const WALK_SPEED = 300.0
const DASH_SPEED = 900.0
const MAX_DASH_DISTANCE = 250.0

const MAX_HEALTH := 100
const ARROW_SCENE := preload("res://arrow.tscn")

enum State { WALK, DASH }
var current_state = State.WALK

var sync_position: Vector2

var dash_direction := Vector2.ZERO
var distance_traveled := 0.0
var last_valid_direction := Vector2.RIGHT

var health: int = MAX_HEALTH

@onready var health_bar: ProgressBar = $HealthBar


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	sync_position = global_position


func _ready() -> void:
	if is_multiplayer_authority():
		position.x = randi_range(50, 550)
		position.y = randi_range(50, 550)

	health_bar.max_value = MAX_HEALTH
	health_bar.value = health


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO

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

		if Input.is_action_just_pressed("shoot"):
			if last_valid_direction != Vector2.ZERO:
				var arrow_dir = (get_global_mouse_position() - global_position).normalized()
				shoot_arrow.rpc(arrow_dir, global_position, name.to_int())

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
				var step_distance := DASH_SPEED * delta
				distance_traveled += step_distance
				if distance_traveled >= MAX_DASH_DISTANCE:
					cancel_dash.rpc(global_position)


@rpc("any_peer", "call_local", "reliable")
func trigger_dash(dir: Vector2, pos: Vector2) -> void:
	global_position = pos
	dash_direction = dir
	distance_traveled = 0.0
	current_state = State.DASH


@rpc("any_peer", "call_local")
func cancel_dash(pos: Vector2) -> void:
	global_position = pos
	current_state = State.WALK
	velocity = Vector2.ZERO


@rpc("any_peer", "call_local", "reliable")
func shoot_arrow(dir: Vector2, pos: Vector2, owner_id: int) -> void:
	var arrow := ARROW_SCENE.instantiate()
	arrow.global_position = pos
	arrow.direction = dir
	arrow.owner_id = owner_id
	get_tree().current_scene.add_child(arrow)


@rpc("any_peer", "call_local", "reliable")
func apply_damage(amount: int) -> void:
	health = max(health - amount, 0)
	health_bar.value = health
