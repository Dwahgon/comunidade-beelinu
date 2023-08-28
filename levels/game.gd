extends Node2D

var player_scene = preload("res://characters/player.tscn")

func _ready():
	MultiplayerManager.player_connected.connect(_on_player_connected)


func _create_player_character(player_data: NetworkPlayerData):
	var player = player_scene.instantiate()
	player.name = str(player_data.id)
	add_child(player)
	player.get_node('PlayerController').player_data = player_data
	print(MultiplayerManager.my_player_data.id, " - Created ", player_data.position)
	player.global_position = player_data.position
	return player


func _on_player_connected(player_data: NetworkPlayerData):
	print(MultiplayerManager.my_player_data.id, " - Created ", player_data.id)
	_create_player_character(player_data)
