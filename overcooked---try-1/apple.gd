extends Area2D

var owner_node: Node2D = null


func _physics_process(_delta: float) -> void:
	if not owner_node: return
	
	position = owner_node.position + Vector2(0, -20)


@rpc("any_peer", "call_local", "reliable")
func request_pickup(owner_path: NodePath):
	if not multiplayer.is_server(): return
	
	if owner_node != null: return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	set_ownership.rpc(sender_id, owner_path)


@rpc("any_peer", "call_local", "reliable")
func request_drop():
	if not multiplayer.is_server(): return 
	
	if owner_node == null: return
	
	set_ownership.rpc(1, NodePath(""))


@rpc("any_peer", "call_local", "reliable")
func set_ownership(new_owner: int, owner_path: NodePath) -> void:
	if not multiplayer.get_remote_sender_id() == 1: return
	
	set_multiplayer_authority(new_owner)
	
	if owner_node != null and owner_node.has_method("set_held_item"):
		owner_node.set_held_item(null)
	
	if owner_path.is_empty():
		owner_node = null
	else:
		owner_node = get_node_or_null(owner_path)
		if owner_node != null and owner_node.has_method("set_held_item"):
			owner_node.set_held_item(self)
