extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.player_loaded.rpc_id(1)


func start_game():
	print("Game Started")
