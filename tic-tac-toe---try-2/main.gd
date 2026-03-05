extends Control

@onready var network_ui: HBoxContainer = $CenterContainer/VBoxContainer/NetworkUI
@onready var host_button: Button = $CenterContainer/VBoxContainer/NetworkUI/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/NetworkUI/JoinButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var area_grid: GridContainer = $CenterContainer/VBoxContainer/AreaGrid
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var address_edit: LineEdit = $CenterContainer/VBoxContainer/NetworkUI/AddressEdit
@onready var port_edit: LineEdit = $CenterContainer/VBoxContainer/NetworkUI/PortEdit

const WIN_COMBINATIONS = [
	[0, 1, 2], [3, 4, 5], [6, 7, 8],
	[0, 3, 6], [1, 4, 7], [2, 5, 8],
	[0, 4, 8], [2, 4, 6]
]

var board_state: Array[int]
var curr_player_id: int
var next_starting_player: int = 1
var players = {}


func _ready() -> void:
	for i in range(9):
		var area = area_grid.get_child(i) as Button
		area.pressed.connect(_on_area_pressed.bind(i))


func host_server(port: int = 8910):
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 1)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	players[multiplayer.get_unique_id()] = 1
	status_label.text = "Waiting player 2..."


func join_server(address: String = "127.0.0.1", port: int = 8910):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	status_label.text = "Connected. Waiting server..."


func _on_peer_connected(id: int):
	players[id] = 2
	if multiplayer.is_server():
		start_game()


func _on_area_pressed(area_index: int):
	request_play.rpc_id(1, area_index)


@rpc("any_peer", "call_local", "reliable")
func request_play(area_index: int):
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if curr_player_id != sender_id: return
	
	if board_state[area_index] != 0: return
	
	board_state[area_index] = players[sender_id]
	
	var game_state = check_game_state()
	
	if game_state != 0:
		var winner_id = game_state
		
		for player_id in players:
			if game_state == players[player_id]:
				winner_id = player_id
				break
		
		end_game.rpc(winner_id, board_state)
		return
	
	change_curr_player()
	
	sync_game_state.rpc(board_state, curr_player_id)


func change_curr_player():
	for player_id in players:
		if curr_player_id != player_id:
			curr_player_id = player_id
			break


func _on_host_button_pressed() -> void:
	var port = port_edit.text
	host_server(port.to_int())


func _on_join_button_pressed() -> void:
	var address = address_edit.text
	var port = port_edit.text
	join_server(address, port.to_int())


func start_game():
	if not multiplayer.is_server(): return
	
	restart_button.hide()
	
	board_state = []
	for i in range(9):
		board_state.append(0)
	
	curr_player_id = next_starting_player
	
	for player_id in players:
		if next_starting_player != players[player_id]:
			next_starting_player = player_id
			break
	
	sync_game_state.rpc(board_state, curr_player_id)


@rpc("authority", "call_local", "reliable")
func sync_game_state(new_board_state: Array[int], new_player_id: int):
	board_state = new_board_state
	curr_player_id = new_player_id
	
	update_board()
	
	var is_my_turn = curr_player_id == multiplayer.get_unique_id()
	
	var state_msg = "YOUR TURN!" if is_my_turn else "Opponent's turn..."
	status_label.text = state_msg
	
	setAreasActive(is_my_turn)


func setAreasActive(state: bool):
	for area in area_grid.get_children():
		area.disabled = !state


func check_game_state() -> int:
	for combination in WIN_COMBINATIONS:
		var a = board_state[combination[0]]
		var b = board_state[combination[1]]
		var c = board_state[combination[2]]
		
		if a != 0 and a == b and a == c:
			return a
	
	if 0 not in board_state:
		return -1
		
	return 0

func update_board():
	for i in range(9):
		var area = area_grid.get_child(i) as Button
		var area_symbol = ""
		
		if board_state[i] == 1:
			area_symbol = "X"
		elif board_state[i] == 2:
			area_symbol = "O" 
		
		area.text = area_symbol


@rpc("authority", "call_local", "reliable")
func end_game(winner_id: int, final_board: Array[int]):
	board_state = final_board
	update_board()
	
	var did_i_win = winner_id == multiplayer.get_unique_id()
	var result_msg = "YOU WIN!" if did_i_win else "YOU LOSE!"
	status_label.text = result_msg
	
	setAreasActive(false)
	
	if multiplayer.is_server():
		restart_button.show()


func _on_restart_button_pressed() -> void:
	start_game()
