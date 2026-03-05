extends CharacterBody2D

const SPEED: float = 300.0

@onready var interaction_zone: Area2D = $InteractionZone

var held_item: Node2D = null

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	velocity = direction * SPEED
	move_and_slide()
	
	if Input.is_action_just_pressed("interact"):
		if held_item != null:
			held_item.request_drop.rpc_id(1)
		else:
			var areas = interaction_zone.get_overlapping_areas()
			for area in areas:
				if area.is_in_group("items"):
					area.request_pickup.rpc_id(1, get_path())
					break


func set_held_item(item: Node2D):
	held_item = item
