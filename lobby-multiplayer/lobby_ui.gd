extends Control


func _ready():
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)


func _on_host_button_pressed() -> void:
	Lobby.player_info.name = $TextEdit.text
	Lobby.create_game()


func _on_join_button_pressed() -> void:
	Lobby.player_info.name = $TextEdit.text
	Lobby.join_game()


func _on_player_connected(id: int, player_info: Dictionary):
	var player_label = Label.new()
	player_label.name = str(id)
	player_label.text = player_info.name
	$PlayerList.add_child(player_label)


func _on_player_disconnected(id: int):
	var node = $PlayerList.get_node_or_null(str(id))
	if node != null:
		node.queue_free()


func _on_start_button_pressed() -> void:
	Lobby.load_game.rpc("res://game.tscn")


func _on_disconnect_button_pressed() -> void:
	Lobby.remove_multiplayer_peer()


func _on_server_disconnected():
	for child in $PlayerList.get_children():
		child.queue_free()
