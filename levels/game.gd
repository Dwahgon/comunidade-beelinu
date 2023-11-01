extends Node2D

const SPAWN_AREA = Vector4i(30, 30, 1100, 600)
var main_menu_scene = load("res://levels/main_menu/main_menu.tscn")
var player_scene = preload("res://characters/player.tscn")
@onready var players_node = $Players

func _ready():
	MultiplayerManager.player_connected.connect(_on_player_connected)
	MultiplayerManager.player_disconnected.connect(_on_player_disconnected)
	MultiplayerManager.server_disconnected.connect(_on_server_disconnected)
	_on_player_connected(MultiplayerManager.my_player_data)


func _create_player_character(player_data: NetworkPlayerData):
	var player = player_scene.instantiate()
	player.name = str(player_data.id)
	player.player_name = player_data.name
	players_node.add_child(player)
	player.get_node('PlayerController').player_data = player_data
	player.global_position = player_data.position
	MultiplayerManager.multiplayer_log("Game", "Player node %d created" % player_data.id)
	return player


func _on_server_disconnected():
	get_tree().change_scene_to_packed(main_menu_scene)

func _on_player_connected(player_data: NetworkPlayerData):
	MultiplayerManager.multiplayer_log("Game", "%d connected. Creating player node." % player_data.id)
	var plr = _create_player_character(player_data)
	if player_data.id == MultiplayerManager.my_id:
		plr._set_player_pos.rpc(Vector2(
			float(SPAWN_AREA.x) + (float(SPAWN_AREA.z) - float(SPAWN_AREA.x)) * randf(), 
			float(SPAWN_AREA.y) + (float(SPAWN_AREA.w) - float(SPAWN_AREA.y)) * randf()
		))


func _on_player_disconnected(player_data: NetworkPlayerData):
	MultiplayerManager.multiplayer_log("Game", "%d disconnected. Removing player node." % player_data.id)
	var player_id_str = str(player_data.id)
	if players_node.has_node(player_id_str):
		players_node.get_node(player_id_str).queue_free()
