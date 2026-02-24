extends Area2D

const SPEED = 2000.0
var lifespan = 2.0
var shooter_id = 0
var pierces_left = 1


func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
	lifespan -= delta
	if lifespan <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		if body.name != str(shooter_id):
			
			if multiplayer.get_unique_id() == shooter_id:
				body.take_damage.rpc_id(body.name.to_int(), 10)
			
			_test_despawn()
	elif body.is_in_group("mobs"):
		if multiplayer.get_unique_id() == shooter_id:
			var mob_authority = body.get_multiplayer_authority()
			body.take_damage.rpc_id(mob_authority, 10)
		_test_despawn()


func _test_despawn():
	if pierces_left == 0:
		queue_free()
		return
	pierces_left -= 1
