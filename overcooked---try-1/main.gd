extends Node2D

@export var player_scene: PackedScene
@export var apple_scene: PackedScene


func _ready() -> void:
	$PlayerSpawner.spawn_function = _custom_spawn_player


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)
	$CanvasLayer.hide()
	
	var apple = apple_scene.instantiate()
	apple.position = Vector2(randi_range(50, 550), randi_range(50, 550))
	$ItemSpawner.add_child(apple, true)


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()


func spawn_player(id: int):
	var player_position = Vector2(randi_range(50, 550), randi_range(50, 550))
	
	var data = {
		"id": id,
		"position": player_position
	}
	
	$PlayerSpawner.spawn(data)


func _custom_spawn_player(data: Dictionary):
	var new_player = player_scene.instantiate()
	new_player.name = str(data.id)
	new_player.position = data.position
	
	return new_player
