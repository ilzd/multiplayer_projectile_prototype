extends Area2D

#const PICKUP_RANGE: float = 80.0

var item_data: Dictionary = {
	"id": "gold_coin",
	"name": "Shiny Gold Coin",
	"value": 10
}


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		requst_interact.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func requst_interact():
	if not multiplayer.is_server(): return
	var requester_id = multiplayer.get_remote_sender_id()
	
	var player = ServerManager.active_players.get(requester_id)
	
	if player:
		player.set_interact_target(self)


func execute_pickup(player_id: int):
	var player = ServerManager.active_players.get(player_id)
	if player:
		player.add_item_to_inventory(item_data)
	
	queue_free()


#@rpc("any_peer", "call_local", "reliable")
#func request_pickup():
	#if not multiplayer.is_server(): return
	#
	#var requester_id = multiplayer.get_remote_sender_id()
	#var players_node = get_node("/root/Main/Players")
	#var player = players_node.get_node_or_null(str(requester_id))
	#
	#if player:
		#var distance = global_position.distance_to(player.global_position)
		#
		#if distance <= PICKUP_RANGE:
			#print("SUCCESS: Player ", requester_id, " picked up the item!")
			#queue_free()
		#else:
			#print("DENIED: Player ", requester_id, " is too far away! Distance: ", distance)
		#
