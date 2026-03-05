extends Area2D

var speed: float = 800.0
var direction: Vector2 = Vector2.ZERO
var shooter_id: int = 0
var type: String = "slow"


func _ready() -> void:
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
	
	get_tree().create_timer(3.0).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body):
	if not multiplayer.is_server(): return
	
	if body is CharacterBody2D and body.name.to_int() != shooter_id:
		if type == "slow":
			body.apply_slow.rpc(0.5, 2.0)
		elif type == "tether":
			body.apply_tether.rpc(global_position, 3.0)
		
		queue_free()
