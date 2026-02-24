extends Node2D

var player_scene = preload("res://player.tscn")

var peer: ENetMultiplayerPeer


func _on_host_button_pressed() -> void:
	hide_ui()
	peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player(multiplayer.get_unique_id())


func _on_join_button_pressed() -> void:
	hide_ui()
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer


func hide_ui():
	$CanvasLayer.hide()


func add_player(id: int):
	var new_player = player_scene.instantiate()
	new_player.name = str(id)
	$PlayerList.add_child(new_player)
