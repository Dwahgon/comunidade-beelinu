extends VBoxContainer

@onready var ip_text_editor = $IP
@onready var port_text_editor = $Port
@onready var error_label = $Error

var level_to_load = preload("res://levels/game.tscn")

func _on_submit_pressed():
	var ip = ip_text_editor.text if not ip_text_editor.text.is_empty() else MultiplayerManager.DEFAULT_IP
	var port = int(port_text_editor.text) if not port_text_editor.text.is_empty() else MultiplayerManager.DEFAULT_PORT
	var error = MultiplayerManager.create_client(ip, port)
	if error:
		error_label.text = "Error code %d" % error
	else:
		get_tree().change_scene_to_packed(level_to_load)
