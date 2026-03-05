extends Node2D

@onready var host_button: Button = $CanvasLayer/NetworkUI/HostButton
@onready var join_button: Button = $CanvasLayer/NetworkUI/JoinButton
@onready var lines_container: Node2D = $LinesContainer
@onready var network_ui: HBoxContainer = $CanvasLayer/NetworkUI

var current_drawer_id: int = 1
var is_drawing: bool = false
var current_line: Line2D



func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	network_ui.hide()
	multiplayer.peer_connected.connect(_send_history_to_new_player)


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	network_ui.hide()


func _unhandled_input(event: InputEvent) -> void:
	if multiplayer.get_unique_id() != current_drawer_id: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_drawing = true
			request_start_line.rpc_id(1, get_global_mouse_position())
		else:
			is_drawing = false
	elif event is InputEventMouseMotion and is_drawing:
		if current_line and current_line.points.size() > 0:
			var last_point = current_line.points[-1]
			
			var mouse_pos = get_global_mouse_position()
			if last_point.distance_to(mouse_pos) > 5.0:
				request_add_point.rpc_id(1, mouse_pos)


@rpc("any_peer", "call_local", "reliable")
func request_start_line(start_pos: Vector2):
	if not multiplayer.is_server(): return
	
	if multiplayer.get_remote_sender_id() != current_drawer_id: return
	
	sync_start_line.rpc(start_pos)


@rpc("any_peer", "call_local", "reliable")
func request_add_point(new_pos: Vector2):
	if not multiplayer.is_server(): return
	if multiplayer.get_remote_sender_id() != current_drawer_id: return
	
	sync_add_point.rpc(new_pos)


func get_new_line():
	var new_line = Line2D.new()
	new_line.default_color = Color.WHITE
	new_line.width = 5.0
	new_line.joint_mode = Line2D.LINE_JOINT_ROUND
	new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	return new_line

@rpc("authority", "call_local", "reliable")
func sync_start_line(start_pos: Vector2):
	current_line = get_new_line()
	
	current_line.add_point(start_pos)
	lines_container.add_child(current_line)


@rpc("authority", "call_local", "unreliable")
func sync_add_point(new_pos: Vector2):
	if not current_line: return
	current_line.add_point(new_pos)


func _send_history_to_new_player(peer_id: int):
	if not multiplayer.is_server(): return
	
	var history_data: Array = []
	
	for line in lines_container.get_children():
		if line is Line2D:
			history_data.append(line.points)
		
		receive_canvas_history.rpc_id(peer_id, history_data)


@rpc("authority", "call_remote", "reliable")
func receive_canvas_history(history_data: Array):
	for points_array in history_data:
		var historical_line = get_new_line()
		historical_line.points = points_array
		lines_container.add_child(historical_line)
