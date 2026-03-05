extends Node2D

@onready var player_spawner: MultiplayerSpawner = $Players/PlayerSpawner
@onready var loot_spawner: MultiplayerSpawner = $LootContainer/LootSpawner
@onready var loot_container: Node2D = $LootContainer
@onready var player_scene: PackedScene = preload("res://player.tscn")
@onready var loot_scene: PackedScene = preload("res://loot_item.tscn")


func _ready() -> void:
	player_spawner.spawn_function = _custom_player_spawn
	loot_spawner.spawn_function = _custom_loot_spawn


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	$CanvasLayer.hide()
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)
	for i in range(10):
		spawn_loot()


func spawn_loot():
	if not multiplayer.is_server(): return
	
	var start_pos = Vector2(randf_range(50, 650), randf_range(50, 650))
	var default_item = {
		"id": "gold_coin",
		"name": "Shiny Gold Coin",
		"value": 10
	}
	
	var spawn_payload = {
		"position": start_pos,
		"item_data": default_item
	}
	
	loot_spawner.spawn(spawn_payload)


func _custom_loot_spawn(data: Dictionary):
	var new_loot = loot_scene.instantiate()
	
	new_loot.position = data.position
	new_loot.item_data = data.item_data
	
	return new_loot


func spawn_player(id: int):
	var start_pos = Vector2(randf_range(50, 650), randf_range(50, 650))
	var spawn_data = {
		"id": id,
		"position": start_pos
	}
	player_spawner.spawn(spawn_data)


func _custom_player_spawn(data: Dictionary):
	var new_player = player_scene.instantiate()
	
	new_player.name = str(data["id"])
	new_player.position = data["position"]
	
	return new_player
