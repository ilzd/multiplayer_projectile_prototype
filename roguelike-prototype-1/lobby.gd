extends Control

@onready var ip_input: LineEdit = $MenuBox/IPInput
@onready var name_input: LineEdit = $MenuBox/NameInput
@onready var player_list: ItemList = $ListBox/PlayerList
@onready var start_button: Button = $ListBox/StartButton
@onready var menu_box: VBoxContainer = $MenuBox


func _ready():
	NetworkManager.player_list_changed.connect(_on_player_list_changed)
	NetworkManager.connected_to_server_successfully.connect(_on_connected_to_server_successfully)


func _on_host_button_pressed() -> void:
	if name_input.text == "": return
	NetworkManager.host_game(name_input.text)
	menu_box.hide()
	start_button.show()
	_on_player_list_changed()


func _on_join_button_pressed() -> void:
	if name_input.text == "": return
	var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
	
	NetworkManager.join_game(ip, name_input.text )


func _on_connected_to_server_successfully():
	menu_box.hide()


func _on_player_list_changed():
	player_list.clear()
	
	for id in NetworkManager.players:
		var player_name = NetworkManager.players[id]["name"]
		if id == 1:
			player_list.add_item(player_name + " (HOST)")
		else:
			player_list.add_item(player_name)	


func _on_start_button_pressed() -> void:
	hide()
	NetworkManager.start_game()
