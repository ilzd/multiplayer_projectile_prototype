extends CharacterBody2D

const SPEED: float = 300.0

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer_synchronizer.public_visibility = false


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	velocity = direction * SPEED
	move_and_slide()
