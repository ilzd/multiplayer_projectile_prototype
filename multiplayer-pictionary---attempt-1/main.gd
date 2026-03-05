extends Node2D

@onready var network_container: HBoxContainer = $UI/NetworkContainer
@onready var lines: Node2D = $Lines
@onready var finish_button: Button = $UI/FinishButton

var current_drawer_id: int
var current_line: Line2D
var is_drawing: bool = false
var current_color: Color = Color.BLACK

var peer_ids = []


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(8910)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	peer_ids.append(multiplayer.get_unique_id())
	network_container.hide()
	change_current_drawer()


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 8910)
	multiplayer.multiplayer_peer = peer
	network_container.hide()


func create_line(color: Color = Color.BLACK):
	var new_line = Line2D.new()
	new_line.default_color = color 
	new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	new_line.joint_mode = Line2D.LINE_JOINT_ROUND
	return new_line


func _unhandled_input(event: InputEvent) -> void:
	if multiplayer.get_unique_id() != current_drawer_id: return
	
	var mouse_position = get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_drawing = true
			request_new_line.rpc_id(1, mouse_position, current_color)
		else:
			is_drawing = false
	elif event is InputEventMouseMotion:
		if current_line and is_drawing:
			var last_point = current_line.points[-1]
			if last_point.distance_to(mouse_position) > 5.0:
				request_add_point.rpc_id(1, mouse_position)
	
	if event.is_action_pressed("ui_left"):
		current_color = Color.GREEN
	elif event.is_action_pressed("ui_right"):
		current_color = Color.RED
	elif event.is_action_pressed("ui_up"):
		current_color = Color.BLUE
	elif event.is_action_pressed("ui_down"):
		current_color = Color.BLACK


@rpc("any_peer", "call_local", "reliable")
func request_add_point(new_point: Vector2):
	if not multiplayer.is_server(): return
	if not current_line: return
	if multiplayer.get_remote_sender_id() != current_drawer_id: return
	
	sync_add_point.rpc(new_point)

@rpc("authority", "call_local", "unreliable")
func sync_add_point(new_point: Vector2):
	current_line.add_point(new_point)


@rpc("any_peer", "call_local", "reliable")
func request_new_line(start_point: Vector2, color: Color = Color.BLACK):
	if not multiplayer.is_server(): return
	if multiplayer.get_remote_sender_id() != current_drawer_id: return
	
	sync_new_line.rpc(start_point, color)


@rpc("authority", "call_local", "reliable")
func sync_new_line(start_point: Vector2, color: Color):
	var new_line = create_line(color)
	new_line.add_point(start_point)
	
	current_line = new_line
	lines.add_child(new_line)


@rpc("authority", "call_local", "reliable")
func sync_line(points: Array, color: Color = Color.BLACK):
	var new_line = create_line(color)
	for point in points:
		new_line.add_point(point)
	lines.add_child(new_line, true)


@rpc("any_peer", "call_local", "reliable")
func request_finish():
	if not multiplayer.is_server(): return
	if multiplayer.get_remote_sender_id() != current_drawer_id: return
	
	change_current_drawer()
	sync_clear_draw.rpc()


@rpc("authority", "call_local", "reliable")
func sync_clear_draw():
	for line in lines.get_children():
		line.queue_free()


func change_current_drawer():
	if current_drawer_id == null:
		current_drawer_id = peer_ids[0]
		return
	
	print(peer_ids)
	var first_element = peer_ids.pop_front()
	print(peer_ids)
	peer_ids.append(first_element)
	
	print(peer_ids)
	sync_curr_drawer_id.rpc(peer_ids[0])


func _on_peer_connected(id: int):
	if not multiplayer.is_server(): return
	
	peer_ids.append(id)
	
	for line in lines.get_children():
		var points = line.points
		sync_line.rpc_id(id, points, line.default_color)


func _on_finish_button_pressed() -> void:
	request_finish.rpc_id(1)


@rpc("authority", "call_local", "reliable")
func sync_curr_drawer_id(id: int):
	current_drawer_id = id
	finish_button.visible = id == multiplayer.get_unique_id()
