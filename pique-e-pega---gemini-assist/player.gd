extends CharacterBody2D

const TETHER_RADIUS = 100.0

@onready var tag_hitbox: Area2D = $TagHitbox
@onready var color_rect: ColorRect = $ColorRect

var base_speed: float = 400.0
var current_speed: float = 400.0
var is_dashing: bool = false
var is_stunned: bool = false
var is_tethered: bool = false
var tether_center: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	if multiplayer.is_server():
		tag_hitbox.body_entered.connect(_on_hitbox_body_entered)


func _on_hitbox_body_entered(body):
	if not multiplayer.is_server(): return
	
	if body is CharacterBody2D and body != self:
		var my_id = name.to_int()
		var other_id = body.name.to_int()
		var map_node = get_node("/root/Map")
		if map_node:
			map_node.handle_tag(my_id, other_id)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if not is_dashing and not is_stunned:
		var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		velocity = dir * current_speed
	elif is_stunned:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	if is_tethered:
		if global_position.distance_to(tether_center) > TETHER_RADIUS:
			var direction_from_center = tether_center.direction_to(global_position)
			global_position = tether_center + direction_from_center * TETHER_RADIUS


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if not event.is_pressed(): return
	
	var target_pos = get_global_mouse_position()
	
	if event.is_action_pressed("skill_1"):
		request_use_skill.rpc_id(1, 0, target_pos)
	elif event.is_action_pressed("skill_2"):
		request_use_skill.rpc_id(1, 1, target_pos)
	elif event.is_action_pressed("skill_3"):
		request_use_skill.rpc_id(1, 2, target_pos)


@rpc("any_peer", "call_local", "reliable")
func request_use_skill(skill_slot: int, target_pos: Vector2):
	if not multiplayer.is_server(): return
	
	if is_stunned: return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if not sender_id == name.to_int(): return
	
	var skills_container = get_node_or_null("Skills")
	if skills_container and skill_slot < skills_container.get_child_count():
		var skill_node = skills_container.get_child(skill_slot)
		skill_node.request_execute(target_pos)


@rpc("any_peer", "call_local", "reliable")
func apply_speed_boost(multiplier: float, duration: float):
	if multiplayer.get_remote_sender_id() != 1: return
	
	current_speed = base_speed * multiplier
	await get_tree().create_timer(duration).timeout
	current_speed = base_speed


@rpc("any_peer", "call_local", "reliable")
func apply_stun(duration: float):
	if multiplayer.get_remote_sender_id() != 1: return
	
	is_stunned = true
	await get_tree().create_timer(duration).timeout
	is_stunned = false


@rpc("any_peer", "call_local", "reliable")
func apply_dash(direction: Vector2, dash_speed: float, duration: float):
	if multiplayer.get_remote_sender_id() != 1: return
	is_dashing = true
	velocity = direction * dash_speed
	
	await get_tree().create_timer(duration).timeout
	is_dashing = false


@rpc("any_peer", "call_local", "reliable")
func apply_slow(multiplier: float, duration: float):
	if multiplayer.get_remote_sender_id() != 1: return
	
	color_rect.color = Color(0.5, 0.5, 1.0)
	current_speed = base_speed * multiplier
	 
	await get_tree().create_timer(duration).timeout
	
	color_rect.color = Color.WHITE
	current_speed = base_speed


@rpc("any_peer", "call_local", "reliable")
func apply_tether(anchor_pos: Vector2, duration: float):
	if multiplayer.get_remote_sender_id() != 1: return
	is_tethered = true
	tether_center = anchor_pos
	
	await get_tree().create_timer(duration).timeout
	
	is_tethered = false
	queue_redraw()


@rpc("any_peer", "call_local", "reliable")
func apply_invisibility(duration: float):
	if multiplayer.get_remote_sender_id() != 1: return
	
	if is_multiplayer_authority():
		color_rect.modulate.a = 0.3
	else:
		color_rect.modulate.a = 0.0
	
	await get_tree().create_timer(duration).timeout
	
	color_rect.modulate.a = 1.0


func _process(_delta: float) -> void:
	if is_tethered:
		queue_redraw()


func _draw() -> void:
	if is_tethered:
		var local_anchor = to_local(tether_center)
		draw_line(Vector2.ZERO, local_anchor, Color.ORANGE, 4.0)
		
		draw_circle(local_anchor, TETHER_RADIUS, Color(1.0, 0.5, 0.0, 0.15))
