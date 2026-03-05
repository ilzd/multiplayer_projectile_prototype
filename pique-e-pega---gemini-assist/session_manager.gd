extends Node

signal players_updated
signal all_players_loaded

const MAP = preload("uid://br1v30g2yld25")

const AVAILABLE_SKILLS = {
	1: "Dash",
	2: "Speed Boost",
	3: "AoE Stun",
	4: "Slow Projectile",
	5: "Tether Projectile",
	6: "Invisibility"
}

var players: Dictionary = {}
var loaded_players_count: int = 0


@rpc("any_peer", "call_local", "reliable")
func player_finished_loading():
	if not multiplayer.is_server(): return
	
	loaded_players_count += 1
	print("player finished ", multiplayer.get_remote_sender_id())
	
	if loaded_players_count == players.size():
		print("SERVER: All clients successfully loaded the map!")
		all_players_loaded.emit()
		loaded_players_count = 0


func add_player(id: int):
	players[id] = {
		"name": "Jogador " + str(id),
		"color": Color(randf(), randf(), randf()),
		"is_ready": false,
		"skills": [],
		"score": 0
	}


func remove_player(id: int):
	players.erase(id)


@rpc("any_peer", "call_local", "reliable")
func request_update_info(new_name: String, new_color: Color, is_ready: bool, skills: Array):
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if not players.has(sender_id): return
	
	var valid_skills = []
	for skill_id in skills:
		if AVAILABLE_SKILLS.has(skill_id) and not valid_skills.has(skill_id):
			valid_skills.append(skill_id)
	
	if valid_skills.size() != 3:
		is_ready = false
	
	players[sender_id]["name"] = new_name
	players[sender_id]["color"] = new_color
	players[sender_id]["is_ready"] = is_ready
	players[sender_id]["skills"] = valid_skills
	
	sync_players.rpc(players)
	check_start_game()


func check_start_game():
	if players.size() < 1: return
	
	for p in players.values():
		if not p["is_ready"]: return
	
	print("SERVIDOR: Todos prontos! Iniciando partida...")
	load_game_scene.rpc()


@rpc("authority", "call_local", "reliable")
func load_game_scene():
	get_tree().change_scene_to_packed(MAP)


@rpc("authority", "call_local", "reliable")
func sync_players(server_players: Dictionary):
	players = server_players
	players_updated.emit()
