extends CharacterBody2D

const SPEED: float = 300.0

var held_item: Node2D = null


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	velocity = direction * SPEED
	move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		print("1")
		if held_item != null:
			print("2")
			held_item.request_drop.rpc_id(1)
		else:
			print("3")
			var areas = $InteractiveArea.get_overlapping_areas()
			for area in areas:
				if area.is_in_group("items"):
					print("4")
					area.request_pickup.rpc_id(1, get_path())
					break


func set_held_item(item: Node2D):
	held_item = item
