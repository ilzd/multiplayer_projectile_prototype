extends CharacterBody2D

@export var health := 100.0
const SPEED := 300.0
var current_weapon = "Bow"
var arrow_scene = preload("res://arrow.tscn")

func _ready():
	reset()
	if has_meta("starting_weapon"):
		current_weapon = get_meta("starting_weapon")
		print("Player ", name, " spawneg with ", current_weapon)


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func reset():
	var viewport_size = get_viewport_rect().size
	health = 100.0
	position.x = randi_range(50, viewport_size.x - 50)
	position.y = randi_range(50, viewport_size.y - 50)


func _process(_delta: float) -> void:
	if has_node("HealthBar"):
		$HealthBar.value = health
		$HealthBar.rotation = -global_rotation

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()	
	
	look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("attack"):
		if current_weapon == "Bow":
			shoot_arrow.rpc(global_position, rotation, multiplayer.get_unique_id())
		elif current_weapon == "Sword":
			swing_sword()

@rpc("any_peer", "call_local")
func shoot_arrow(spawn_position, spawn_rotation, shooter_id):
	var arrow = arrow_scene.instantiate() as Area2D
	arrow.global_position = spawn_position
	arrow.rotation = spawn_rotation
	arrow.shooter_id = shooter_id
	get_tree().current_scene.add_child(arrow)

func swing_sword():
	show_sword_slash.rpc()
	var hit_targets = $MeleeHitbox.get_overlapping_bodies() as Array[Node2D]
	for target in hit_targets:
		if target == self:
			continue
		if target.is_in_group("mobs") or target.is_in_group("players"):
			var authority_id = target.get_multiplayer_authority()
			target.take_damage.rpc_id(authority_id, 20)


@rpc("any_peer", "call_local")
func show_sword_slash():
	$MeleeVisual.show()
	await get_tree().create_timer(0.1).timeout
	$MeleeVisual.hide()

@rpc("any_peer")
func take_damage(amount: int):
	if is_multiplayer_authority():
		health = max(0, health - amount)
		
		if(health <= 0):
			reset()
		
		$ColorRect.color = Color.RED
		await get_tree().create_timer(0.1).timeout
		$ColorRect.color = Color.WHITE
