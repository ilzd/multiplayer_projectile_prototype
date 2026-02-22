extends Node2D

var peer: ENetMultiplayerPeer
var player_scene = preload("res://player.tscn")
@export var mob_scene: PackedScene


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_remove_player)
	
	$PlayerSpawner.spawn_function = _custom_player_spawn


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print(multiplayer.get_unique_id())

func _on_host_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	
	var option = $CanvasLayer/OptionButton
	var my_weapon = option.get_item_text(option.selected)
	_register_player(multiplayer.get_unique_id(), my_weapon)
	
	$CanvasLayer/DisconnectButton.show()
	$CanvasLayer/HostButton.hide()
	$CanvasLayer/JoinButton.hide()
	$CanvasLayer/OptionButton.hide()
	_spawn_mobs()


func _on_join_button_pressed() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connection_success)
	
	$CanvasLayer/DisconnectButton.show()
	$CanvasLayer/HostButton.hide()
	$CanvasLayer/JoinButton.hide()
	$CanvasLayer/OptionButton.hide()

func _on_connection_success():
	var option = $CanvasLayer/OptionButton
	var my_weapon = option.get_item_text(option.selected)
	var my_id = multiplayer.get_unique_id()
	_register_player.rpc_id(1, my_id, my_weapon)


func _on_disconnect_button_pressed() -> void:
	peer.close()
	multiplayer.multiplayer_peer = null
	
	for child in $PlayerList.get_children():
		child.queue_free()
	
	for child in $MobList.get_children():
		child.queue_free()
	
	$CanvasLayer/DisconnectButton.hide()
	$CanvasLayer/HostButton.show()
	$CanvasLayer/JoinButton.show()
	$CanvasLayer/OptionButton.show()


@rpc("any_peer", "call_local")
func _register_player(id: int, weapon: String):
	if multiplayer.is_server():
		var spawn_data = {
			"id": id,
			"weapon": weapon
		}
		$PlayerSpawner.spawn(spawn_data)

func _spawn_mobs():
	for i in range(3):
		var new_mob = mob_scene.instantiate()
		new_mob.name = "Mob_" + str(i)
		$MobList.add_child(new_mob)


func _remove_player(id):
	var player_node = $PlayerList.get_node_or_null(str(id))
	
	if player_node != null:
		player_node.queue_free()


func _custom_player_spawn(data: Dictionary):
	var player = player_scene.instantiate()
	player.name = str(data.id)
	player.set_meta("starting_weapon", data.weapon)
	return player

#func _add_player(id):
	#var new_player = player_scene.instantiate()
	#new_player.name = str(id)
	#$PlayerList.add_child(new_player)
