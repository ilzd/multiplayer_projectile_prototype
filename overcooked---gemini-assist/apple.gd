extends Area2D

var holder_node: Node2D = null


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority() and holder_node != null:
		global_position = holder_node.global_position + Vector2(0, -40)


@rpc("any_peer", "call_local", "reliable")
func request_pickup(player_path: NodePath):
	if not multiplayer.is_server(): return
	
	if holder_node != null: return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	set_ownership.rpc(sender_id, player_path)


@rpc("any_peer", "call_local", "reliable")
func request_drop():
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	if get_multiplayer_authority() != sender_id: return
	
	set_ownership.rpc(1, NodePath(""))


@rpc("any_peer", "call_local", "reliable")
func set_ownership(new_auth: int, player_path: NodePath):
	var sender = multiplayer.get_remote_sender_id()
	if sender != 1: return
	
	set_multiplayer_authority(new_auth)
	
	if holder_node and holder_node.has_method("set_held_item"):
		holder_node.set_held_item(null)
	
	if player_path.is_empty():
		holder_node = null
	else:
		holder_node = get_node_or_null(player_path)
		if holder_node and holder_node.has_method("set_held_item"):
			holder_node.set_held_item(self)
