extends Node2D
class_name SkillBase

@export var cooldown_time: float = 3.0
var is_on_cooldown: bool = false

@onready var player: CharacterBody2D = get_parent().get_parent()


func request_execute(target_pos: Vector2):
	if not multiplayer.is_server(): return
	if is_on_cooldown: return
	
	is_on_cooldown = true
	start_cooldown_timer()
	
	_execute_skill(target_pos)


func _execute_skill(_target_pos: Vector2):
	pass


func start_cooldown_timer():
	await get_tree().create_timer(cooldown_time).timeout
	is_on_cooldown = false
