extends Area2D
class_name LootItem

var item_data: Dictionary = {}
var picked: bool = false


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("move"):
		request_pickup.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func request_pickup():
	if not multiplayer.is_server(): return
	var requester_id = multiplayer.get_remote_sender_id()
	var player_node = NetworkManager.players_data.get(requester_id) as Player
	
	if not is_instance_valid(player_node): return
	player_node.start_pickup(self)


func execute_pickup(player_id: int):
	if not multiplayer.is_server(): return
	if picked: return
	
	var player_node = NetworkManager.players_data.get(player_id) as Player
	if not is_instance_valid(player_node): return
	
	if player_node.add_item_to_inventory(item_data):
		picked = true
		queue_free()
