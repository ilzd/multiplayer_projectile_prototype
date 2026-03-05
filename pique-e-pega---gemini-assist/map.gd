extends Node2D

const TAG_COOLDOWN_TIME: float = 1.5

const SKILL_SCENES = {
	1: preload("res://skills/skill_dash.tscn"),
	2: preload("res://skills/skill_speed_boost.tscn"),
	3: preload("res://skills/skill_aoe_stun.tscn"),
	4: preload("res://skills/skill_slow_proj.tscn"),
	5: preload("res://skills/skill_tether_proj.tscn"),
	6: preload("res://skills/skill_inv_proj.tscn")
}

@onready var players: Node2D = $Players
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var match_timer: Timer = $MatchTimer
@onready var time_label: Label = $HUD/TimeLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var scores_label: Label = $HUD/ScoresLabel
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner

var current_seeker_id: int = 0
var time_left: int = 60
var seeker_queue: Array = []
var is_tag_cooldown: bool = false


func _ready() -> void:
	player_spawner.spawn_function = _custom_player_spawn
	projectile_spawner.spawn_function = _custom_projectile_spawn
	
	if multiplayer.is_server():
		SessionManager.all_players_loaded.connect(start_match)
		match_timer.timeout.connect(_on_server_timer_tick)
	
	SessionManager.player_finished_loading.rpc_id(1)


func start_match():
	for peer_id in SessionManager.players:
		player_spawner.spawn(peer_id)
		seeker_queue.append(peer_id)
	
	start_new_turn()


func start_new_turn():
	if seeker_queue.is_empty():
		print("SERVER: Round Over! Everyone has started as the Seeker.")
		return
	
	current_seeker_id = seeker_queue.pop_front()
	time_left = 60
	
	match_timer.start()
	sync_match_state.rpc(time_left, current_seeker_id, get_current_scores())


func _on_server_timer_tick():
	time_left -= 1
	
	for peer_id in SessionManager.players:
		if peer_id != current_seeker_id:
			SessionManager.players[peer_id]["score"] += 1
	
	sync_match_state.rpc(time_left, current_seeker_id, get_current_scores())
	
	if time_left <= 0:
		match_timer.stop()
		start_new_turn()


func get_current_scores():
	var scores = {}
	for id in SessionManager.players:
		scores[id] = SessionManager.players[id]["score"]
		
	return scores


@rpc("authority", "call_local", "reliable")
func sync_match_state(time: int, seeker_id: int, scores: Dictionary):
	time_label.text = "Time left: " + str(time)
	
	var seeker_name = SessionManager.players[seeker_id]["name"]
	status_label.text = "WARNING: " + seeker_name + " is the Seeker!"
	
	if multiplayer.get_unique_id() == seeker_id:
		status_label.modulate = Color.RED
	else:
		status_label.modulate = Color.WHITE
	
	var score_text = "---- SCORES ----\n"
	for id in scores:
		var p_name = SessionManager.players[id]["name"]
		score_text += p_name + ": " + str(scores[id]) + " pts\n"
	scores_label.text = score_text


func _custom_player_spawn(peer_id: int):
	var player_scene = preload("res://player.tscn")
	var new_player = player_scene.instantiate()
	new_player.name = str(peer_id)
	
	var player_data = SessionManager.players[peer_id]
	new_player.get_node("ColorRect").color = player_data["color"]
	
	new_player.global_position = Vector2(randf_range(100, 700), randf_range(100, 500))
	
	var skills_container = Node2D.new()
	skills_container.name = "Skills"
	new_player.add_child(skills_container)
	
	for skill_id in player_data["skills"]:
		if SKILL_SCENES.has(skill_id):
			var skill_instance = SKILL_SCENES[skill_id].instantiate()
			skills_container.add_child(skill_instance)
	
	return new_player


func handle_tag(toucher_id: int, touched_id: int):
	if not multiplayer.is_server(): return
	if toucher_id != current_seeker_id: return
	if is_tag_cooldown: return
	
	current_seeker_id = touched_id
	print("SERVER: TAG! Player ", touched_id, " is now the Seeker!")
	
	sync_match_state.rpc(time_left, current_seeker_id, get_current_scores())
	
	is_tag_cooldown = true
	await get_tree().create_timer(TAG_COOLDOWN_TIME).timeout
	is_tag_cooldown = false


func spawn_projectile(payload: Dictionary):
	if not multiplayer.is_server(): return
	projectile_spawner.spawn(payload)

func _custom_projectile_spawn(data: Dictionary):
	var proj_scene = preload("res://projectiles/projectile.tscn")
	var new_proj = proj_scene.instantiate()
	new_proj.global_position = data["position"]
	new_proj.direction = data["direction"]
	new_proj.shooter_id = data["shooter_id"]
	new_proj.type = data["type"]
	
	return new_proj
