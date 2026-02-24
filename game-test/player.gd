extends CharacterBody2D

const SPEED = 300.0
const DASH_SPEED = 1000.0
const DASH_MAX_DISTANCE = 200.0

var is_dashing := false
var dash_distance := 0.0
var dash_direction := Vector2()

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var direction_x := Input.get_axis("move_left", "move_right")
	var direction_y := Input.get_axis("move_up", "move_down")
	var direction = Vector2(direction_x, direction_y)
	
	if not is_dashing:
		is_dashing = Input.is_action_just_pressed("dash")
		dash_direction = direction
		dash_distance = 0.0
	else:
		dash_distance += DASH_SPEED * delta
		if(dash_distance >= DASH_MAX_DISTANCE):
			is_dashing = false
		
	var final_speed = DASH_SPEED if is_dashing else SPEED
	var final_dir = dash_direction if is_dashing else direction
	
	velocity = final_dir.normalized() * final_speed 
	
	move_and_slide()
