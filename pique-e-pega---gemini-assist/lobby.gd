extends Control

const PORT = 8910
const IP_ADDRESS = "127.0.0.1"

@onready var btn_host: Button = $BtnHost
@onready var btn_join: Button = $BtnJoin
@onready var input_name: LineEdit = $InputName
@onready var color_picker: ColorPickerButton = $ColorPicker
@onready var check_ready: CheckBox = $CheckReady
@onready var player_list: ItemList = $PlayerList
@onready var skill_1: OptionButton = $Skill1
@onready var skill_2: OptionButton = $Skill2
@onready var skill_3: OptionButton = $Skill3


func _ready() -> void:
	for skill_id in SessionManager.AVAILABLE_SKILLS:
		var skill_name = SessionManager.AVAILABLE_SKILLS[skill_id]
		skill_1.add_item(skill_name, skill_id)
		skill_2.add_item(skill_name, skill_id)
		skill_3.add_item(skill_name, skill_id)
	
	skill_1.select(0)
	skill_2.select(1)
	skill_3.select(2)
	
	input_name.text_changed.connect(_on_ui_changed.unbind(1))
	color_picker.color_changed.connect(_on_ui_changed.unbind(1))
	check_ready.toggled.connect(_on_ui_changed.unbind(1))
	skill_1.item_selected.connect(_on_ui_changed.unbind(1))
	skill_2.item_selected.connect(_on_ui_changed.unbind(1))
	skill_3.item_selected.connect(_on_ui_changed.unbind(1))
	
	SessionManager.players_updated.connect(update_ui_list)


func _on_btn_host_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	
	SessionManager.add_player(1)
	SessionManager.sync_players.rpc(SessionManager.players)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	disable_network_buttons()
	_on_ui_changed()


func _on_btn_join_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	
	disable_network_buttons()


func _on_peer_connected(id: int):
	SessionManager.add_player(id)
	SessionManager.sync_players.rpc(SessionManager.players)

func _on_peer_disconnected(id: int):
	SessionManager.remove_player(id)
	SessionManager.sync_players.rpc(SessionManager.players)
	

func disable_network_buttons():
	btn_host.disabled = true
	btn_join.disabled = true


func _on_ui_changed():
	var my_name = input_name.text if input_name.text != "" else "Sem Nome"
	var my_color = color_picker.color
	var is_ready = check_ready.button_pressed
	
	var my_skills = [
		skill_1.get_selected_id(),
		skill_2.get_selected_id(),
		skill_3.get_selected_id()
	]
	
	SessionManager.request_update_info.rpc_id(1, my_name, my_color, is_ready, my_skills)


func update_ui_list():
	player_list.clear()
	for id in SessionManager.players:
		var p = SessionManager.players[id]
		var status = "[PRONTO]" if p["is_ready"] else "[AGUARDANDO]"
		
		var skill_names = []
		for s_id in p["skills"]:
			skill_names.append(SessionManager.AVAILABLE_SKILLS[s_id])
		
		var text = str(id) + " | " + p["name"] + " " + status + " | " + str(skill_names)
		
		player_list.add_item(text)
		var item_index = player_list.item_count - 1
		player_list.set_item_custom_bg_color(item_index, p["color"] * Color(1, 1, 1, 0.5))
