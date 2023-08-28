extends VBoxContainer

@onready var error_label = $Error
var level_to_load = preload("res://levels/game.tscn")

func _on_submit_pressed():
	var error = MultiplayerManager.create_server()
	if error:
		error_label.text = "Error code %d" % error
	else:
		get_tree().change_scene_to_packed(level_to_load)
