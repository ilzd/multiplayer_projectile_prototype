extends Node

const PORT = 8910
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_PLAYERS = 4
const ARENA_PATH = "res://arena.tscn"

var peer: ENetMultiplayerPeer

var players = {}
var players_loaded = 0

signal player_list_changed
signal connected_to_server_successfully
signal connection_failed
signal server_disconnected
signal game_started


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconencted)


func print_info(info: String):
	print("From: ", multiplayer.get_unique_id(), ", Info: ", info)


func _on_peer_connected(id: int):
	print_info(str(id) + " connected")


func _on_peer_disconnected(id: int):
	print_info(str(id) + " disconnected")
	if players.has(id):
		players.erase(id)
		player_list_changed.emit()


func _on_connected_to_server():
	print_info("connected successfully")
	connected_to_server_successfully.emit()
	var my_name = get_meta("my_name")
	var my_id = multiplayer.get_unique_id()
	
	register_player.rpc_id(1, my_id, {"name": my_name, "is_ready": false})


func _on_connection_failed():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	connection_failed.emit()


func _on_server_disconencted():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	server_disconnected.emit()


func host_game(host_name: String):
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	
	players[1] = {
		"name": host_name,
		"is_ready": false
	}
	
	player_list_changed.emit()
	print_info("Server created. Waiting players...")


func join_game(ip: String, player_name: String):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	set_meta("my_name", player_name)


@rpc("any_peer", "call_remote", "reliable")
func register_player(id: int, player_data: Dictionary):
	if multiplayer.is_server():
		players[id] = player_data
		sync_players.rpc(players)


@rpc("any_peer", "call_local", "reliable")
func sync_players(updated_players: Dictionary):
	players = updated_players
	player_list_changed.emit()


func start_game():
	if multiplayer.is_server():
		players_loaded = 0
		load_game_scene.rpc(ARENA_PATH)


@rpc("authority", "call_local", "reliable")
func load_game_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	player_finished_loading.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func player_finished_loading():
	players_loaded += 1
	print_info("Players loaded: " + str(players_loaded) + "/" + str(players.size()))
	if (players_loaded == players.size()):
		print_info("Starting Game...")
		start_playing.rpc()


@rpc("authority", "call_local", "reliable")
func start_playing():
	game_started.emit()
