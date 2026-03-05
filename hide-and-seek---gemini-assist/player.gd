extends CharacterBody2D

@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

const SPEED: float = 300.0


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if multiplayer.is_server():
		synchronizer.public_visibility = false


func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		velocity = dir * SPEED
		move_and_slide()
