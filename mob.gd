extends CharacterBody2D

@export var health: int = 50

func _enter_tree() -> void:
	set_multiplayer_authority(1)
	reset()


func _process(_delta: float) -> void:
	if has_node("HealthBar"):
		$HealthBar.value = health
		$HealthBar.rotation = -global_rotation


func reset():
	var viewport_size = get_viewport_rect().size
	health = 50
	position.x = randi_range(50, viewport_size.x - 50)
	position.y = randi_range(50, viewport_size.y - 50)


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		move_and_slide()

@rpc("any_peer", "call_local")
func take_damage(amount: int):
	if is_multiplayer_authority():
		health = clamp(health - amount, 0, 50)
		
		$ColorRect.color = Color("ffb589ff")
		await get_tree().create_timer(0.1).timeout
		$ColorRect.color = Color("ff6028")
		
		if health <= 0:
			reset()
