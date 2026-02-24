extends Node2D

@export var player_scene: PackedScene

func _ready() -> void:
	NetworkManager.game_started.connect(_on_game_started)


func _on_game_started():
	if multiplayer.is_server():
		spawn_players()


func spawn_players():
	var spawn_index = 0
	for player_id in NetworkManager.players:
		var player_instance = player_scene.instantiate()
		player_instance.name = str(player_id)
		player_instance.global_position = Vector2(100 + spawn_index * 75, 100)
		$Players.add_child(player_instance)
		
		spawn_index += 1
		print("Spawned player: ", player_id)
