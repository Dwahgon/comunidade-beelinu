extends CharacterBody2D

@export var speed: float = 500

var _move_direction := Vector2.ZERO
var _move_distance := 0.0
var player_name: String : 
	set(v):
		player_name = v
		$Name.text = v


func _physics_process(delta: float) -> void:
	_move_character(delta)


func _move_character(delta: float) -> void:
	if _move_distance > 0:
		velocity = _move_direction * speed
		_move_distance = max(_move_distance - speed * delta, 0)
		move_and_slide()
		_set_player_pos.rpc(global_position)


@rpc("any_peer", "call_local", "unreliable")
func _set_player_pos(new_position: Vector2):
	var player_id = multiplayer.get_remote_sender_id()
	global_position = new_position
	MultiplayerManager.players[player_id].position = new_position


func move_to(pos: Vector2) -> void:
	_move_direction = global_position.direction_to(pos)
	_move_distance = global_position.distance_to(pos)
