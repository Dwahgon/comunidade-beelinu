extends Node2D

var player_scene = preload("res://characters/player.tscn")
@onready var players_node = $Players

func _ready():
	MultiplayerManager.player_connected.connect(_on_player_connected)
	MultiplayerManager.player_disconnected.connect(_on_player_disconnected)


func _create_player_character(player_data: NetworkPlayerData):
	var player = player_scene.instantiate()
	player.name = str(player_data.id)
	players_node.add_child(player)
	player.get_node('PlayerController').player_data = player_data
	player.global_position = player_data.position
	MultiplayerManager.log("Player node %d created" % player_data.id)
	return player


func _on_player_connected(player_data: NetworkPlayerData):
	MultiplayerManager.log("%d connected. Creating player node." % player_data.id)
	_create_player_character(player_data)


func _on_player_disconnected(player_id: int):
	MultiplayerManager.log("%d disconnected. Removing player node." % player_id)
	var player_node = players_node.get_node(str(player_id))
	if player_node:
		player_node.queue_free()
