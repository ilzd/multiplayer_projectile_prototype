extends Node2D

var peer: ENetMultiplayerPeer
@export var player_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/HostButton.pressed.connect(_on_host_pressed)
	$CanvasLayer/JoinButton.pressed.connect(_on_join_pressed)
	$CanvasLayer/DisconnectButton.pressed.connect(_on_disconnect_pressed)
	
	multiplayer.peer_disconnected.connect(_remove_player)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"): 
		if multiplayer.is_server():
			print_once_per_client.rpc()

@rpc
func print_once_per_client():
	print("I will be printed to the console once per each connected client.")

func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player(multiplayer.get_unique_id())
	$CanvasLayer/HostButton.hide()
	$CanvasLayer/JoinButton.hide()
	$CanvasLayer/DisconnectButton.show()

func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer/HostButton.hide()
	$CanvasLayer/JoinButton.hide()
	$CanvasLayer/DisconnectButton.show()

func _on_disconnect_pressed():
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	for child in $PlayerList.get_children():
		child.queue_free()
	$CanvasLayer/HostButton.show()
	$CanvasLayer/JoinButton.show()
	$CanvasLayer/DisconnectButton.hide()

func _add_player(id):
	print(id)
	var player = player_scene.instantiate()
	player.name = str(id)
	$PlayerList.add_child(player)


func _remove_player(id):
	var player_node = $PlayerList.get_node_or_null(str(id))
	
	if player_node:
		player_node.queue_free()
