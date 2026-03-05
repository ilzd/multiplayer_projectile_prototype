extends CharacterBody2D

const SPEED: float = 300.0
const PICKUP_RANGE: float = 40.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var camera_2d: Camera2D = $Camera2D

var target_interactable: Node2D = null

var server_inventory: Array = []


func _ready() -> void:
	if multiplayer.is_server():
		ServerManager.active_players[name.to_int()] = self
	
	camera_2d.enabled = name.to_int() == multiplayer.get_unique_id()


func _exit_tree() -> void:
	ServerManager.active_players.erase(name.to_int())


func _unhandled_input(event: InputEvent) -> void:
	if name.to_int() != multiplayer.get_unique_id(): return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var click_position = get_global_mouse_position()
		request_movement.rpc_id(1, click_position)
	elif event is InputEventKey and event.keycode == KEY_Q and event.is_pressed():
		request_drop_item.rpc_id(1, 0)


@rpc("any_peer", "call_local", "reliable")
func request_drop_item(item_index: int):
	if not multiplayer.is_server(): return
	
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != name.to_int(): return
	
	if item_index >= 0 and item_index < server_inventory.size():
		var item_to_drop = server_inventory[item_index]
		server_inventory.remove_at(item_index)
		
		sync_inventory_ui.rpc_id(sender_id, server_inventory)
		
		spawn_dropped_loot(item_to_drop)


func spawn_dropped_loot(item_data: Dictionary):
	var random_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
	var drop_pos = global_position + random_offset
	
	var spawn_payload = {
		"position": drop_pos,
		"item_data": item_data
	}
	
	var loot_spawner = get_node("/root/Main/LootContainer/LootSpawner")
	loot_spawner.spawn(spawn_payload)


@rpc("any_peer", "call_local", "reliable")
func request_movement(target_position: Vector2):
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id() 
	
	if sender_id != name.to_int() and sender_id != 0:
		return
	
	target_interactable = null
	nav_agent.target_position = target_position


func set_interact_target(target: Node2D):
	target_interactable = target
	nav_agent.target_position = target.global_position


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server(): return
	
	if is_instance_valid(target_interactable):
		var distance = global_position.distance_to(target_interactable.global_position)
		if distance <= PICKUP_RANGE:
			nav_agent.target_position = global_position
			target_interactable.execute_pickup(name.to_int())
			target_interactable = null
			return
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_path_position = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		velocity = direction * SPEED
	
	move_and_slide()


func add_item_to_inventory(item_data: Dictionary):
	if not multiplayer.is_server(): return
	
	server_inventory.append(item_data)
	print("SERVER ALERT: Player ", name, " picked up ", item_data["name"])
	print("SERVER ALERT: Player ", name, "'s inventory is now: ", server_inventory)
	sync_inventory_ui.rpc_id(name.to_int(), server_inventory)


@rpc("authority", "call_local", "reliable")
func sync_inventory_ui(updated_inventory: Array):
	print("CLIENT ", multiplayer.get_unique_id(), " UI UPDATE: My new inventory is: ", updated_inventory)
