extends Node2D

const DEFAULT_ITEM_DATA = {
	"id": "gold_coin",
	"name": "Gold Coin"
}

@export var ui: CanvasLayer

@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var loot_spawner: MultiplayerSpawner = $LootSpawner
@onready var players: Node2D = $Players
@onready var loot: Node2D = $Loot
@onready var player_scene: PackedScene = preload("res://player.tscn")
@onready var loot_scene: PackedScene = preload("res://loot_item.tscn")


func _ready() -> void:
	player_spawner.spawn_function = _custom_spawn_player
	loot_spawner.spawn_function = _custom_spawn_loot
	NetworkManager.spawn_item.connect(_on_loot_spawned)
	
	var args = OS.get_cmdline_args()
	var window: Window = get_window()
	var window_size = window.size.x
	
	for arg in args:
		if arg.contains("instance_id"):
			var instance_id = arg[-1].to_int()
			window.position.x = round(50 + window_size * (instance_id * 1.05))
		elif arg.contains("server"):
			_host()


func _host(port: int = 8910):
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	ui.hide()
	multiplayer.peer_connected.connect(add_player)
	
	for i in (range(10)):
		spawn_loot()


func _join(address: String = "127.0.0.1", port: int = 8910):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	ui.hide()


func add_player(id: int):
	if not multiplayer.is_server(): return
	
	var start_pos = Vector2(randf_range(50, 650), randf_range(50, 650))
	
	var spawn_payload = {
		"id": id,
		"position": start_pos
	}
	
	player_spawner.spawn(spawn_payload)


func _custom_spawn_player(data: Dictionary):
	var new_player = player_scene.instantiate()
	
	new_player.name = str(data["id"])
	new_player.global_position = data["position"]
	
	return new_player


func spawn_loot(item_data: Dictionary = DEFAULT_ITEM_DATA):
	var random_position = Vector2(randf_range(50, 650), randf_range(50, 650))
	
	var spawn_payload = {
		"position": random_position,
		"item_data": item_data
	}
	
	NetworkManager.spawn_item.emit(spawn_payload)


func _custom_spawn_loot(data: Dictionary):
	var new_loot = loot_scene.instantiate() as LootItem
	
	new_loot.global_position = data["position"]
	new_loot.item_data = data["item_data"]
	
	return new_loot


func _on_loot_spawned(item_data: Dictionary):
	loot_spawner.spawn(item_data)
