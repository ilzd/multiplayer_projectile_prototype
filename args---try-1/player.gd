extends CharacterBody2D
class_name Player

const SPEED: float = 300.0
const INVENTORY_SIZE: int = 5
const PICKUP_RADIUS: float = 40.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var camera_2d: Camera2D = $Camera2D

var server_inventory: Array[Dictionary] = []
var target_item: LootItem = null


func _ready() -> void:
	NetworkManager.players_data[name.to_int()] = self
	camera_2d.enabled = multiplayer.get_unique_id() == name.to_int()


func _exit_tree() -> void:
	NetworkManager.players_data.erase(multiplayer.get_unique_id())


func _unhandled_input(event: InputEvent) -> void:
	if name.to_int() != multiplayer.get_unique_id(): return
	
	if event.is_action_pressed("move"):
		var target_pos = get_global_mouse_position()
		request_movement.rpc_id(1, target_pos)
	elif event.is_action_pressed("drop"):
		request_drop.rpc_id(1, 0)
		


@rpc("any_peer", "call_remote", "reliable")
func request_movement(target_pos: Vector2):
	if not multiplayer.is_server(): return
	if multiplayer.get_remote_sender_id() != name.to_int(): return
	
	nav_agent.target_position = target_pos
	target_item = null


@rpc("any_peer", "call_remote", "reliable")
func request_drop(item_index: int):
	if not multiplayer.is_server(): return
	if multiplayer.get_remote_sender_id() != name.to_int(): return
	
	if item_index >= 0 and item_index < server_inventory.size():
		var dropped_item_data = server_inventory[item_index]
		server_inventory.remove_at(item_index)
		update_inventory_ui.rpc_id(name.to_int(), server_inventory)
		
		var spawn_pos = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var spawn_payload = {
			"position": spawn_pos,
			"item_data": dropped_item_data
		}
		NetworkManager.spawn_item.emit(spawn_payload)


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server(): return
	
	if target_item:
		var distance = global_position.distance_to(target_item.global_position)
		if distance <= PICKUP_RADIUS:
			target_item.execute_pickup(name.to_int())
			target_item = null
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next_pos = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_pos)
		velocity = direction * SPEED
	
	move_and_slide()


func start_pickup(loot_item: LootItem):
	if not multiplayer.is_server(): return
	
	target_item = loot_item
	nav_agent.target_position = loot_item.global_position


func add_item_to_inventory(item_data: Dictionary):
	if not multiplayer.is_server(): return
	if server_inventory.size() >= INVENTORY_SIZE:
		print("Inventory full for player ", name.to_int())
		return false
	
	server_inventory.append(item_data)
	update_inventory_ui.rpc_id(name.to_int(), server_inventory)
	print("Item ", item_data["name"], " picked up by ", name.to_int())
	return true


@rpc("authority", "call_remote", "reliable")
func update_inventory_ui(inventory: Array[Dictionary]):
	print("Updated inventory: ", inventory.map(func(item_data): return item_data["name"]))
