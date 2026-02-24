extends Area2D

@export var speed: float = 600.0
@export var damage: int = 25

var direction: Vector2 = Vector2.RIGHT
var owner_id: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		queue_free()
	)
	timer.start()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if not (body is CharacterBody2D):
		return

	if not body.has_method("apply_damage"):
		return

	var body_id := 0
	if body.name.is_valid_int():
		body_id = body.name.to_int()

	# Don't hit the owner
	if body_id == owner_id:
		return
	
	if multiplayer.get_unique_id() == owner_id:
		body.apply_damage.rpc(damage)
	queue_free()
