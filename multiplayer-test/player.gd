extends CharacterBody2D

@export var health := 10
const SPEED := 300.0
const DASH_MULTIPLIER = 4.0 # O dash será 4x mais rápido que o movimento normal
const DASH_DURATION = 0.15 # O dash vai durar 0.15 segundos
var is_dashing = false
var dash_timer = 0.0
var last_direction = Vector2.RIGHT # Direção padrão inicial

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	 
	if Input.is_action_just_pressed("attack"):
		attack()
		
	if direction != Vector2.ZERO:
		last_direction = direction
	if is_dashing:
		dash_timer -= delta # Diminui o tempo restante do dash
		if dash_timer <= 0:
			is_dashing = false # O tempo acabou, encerra o dash
		else:
			velocity = last_direction * (SPEED * DASH_MULTIPLIER)
	else:
		velocity = direction * SPEED
		
		# "ui_accept" por padrão no Godot é o Espaço ou Enter
		if Input.is_action_just_pressed("ui_accept"):
			is_dashing = true
			dash_timer = DASH_DURATION # Inicia o cronômetro do dash
	move_and_slide()

func attack():
	var bodies_hit = $Hitbox.get_overlapping_bodies() as Array[Node2D]
	
	for body in bodies_hit:
		if body.is_in_group("players") and body != self:
			var enemy_owner = body.get_multiplayer_authority()
			body.take_damage.rpc_id(enemy_owner, 1)


@rpc("any_peer", "call_local")
func take_damage(amount: int):
	print("take_damage")
	if is_multiplayer_authority():
		health -= amount
		
		$ColorRect.color = Color.RED
		await get_tree().create_timer(0.2).timeout
		
		$ColorRect.color = Color.WHITE
