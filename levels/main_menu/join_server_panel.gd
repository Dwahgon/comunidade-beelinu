extends VBoxContainer

@onready var name_text_editor = $Name
@onready var ip_text_editor = $IP
@onready var port_text_editor = $Port
@onready var message_label = $Message

var level_to_load = preload("res://levels/game.tscn")

enum MessageTheme {
	ERROR,
	SUCCESS
}

func _on_submit_pressed():
	if (name_text_editor.text.is_empty()):
		display_message("Name must not be empty", MessageTheme.ERROR)
		return
	
	var ip = ip_text_editor.text if not ip_text_editor.text.is_empty() else MultiplayerManager.DEFAULT_IP
	var port = int(port_text_editor.text) if not port_text_editor.text.is_empty() else MultiplayerManager.DEFAULT_PORT
	var error = MultiplayerManager.create_client(name_text_editor.text, ip, port)
	if error:
		display_message("Error code %d" % error, MessageTheme.ERROR)
	else:
		display_message("Connecting...", MessageTheme.SUCCESS)
		_connect_connection_signals()


func _connect_connection_signals():
	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.connection_success.connect(_on_connection_success)


func _disconnect_connection_signals():
	MultiplayerManager.connection_failed.disconnect(_on_connection_failed)
	MultiplayerManager.connection_success.disconnect(_on_connection_success)


func _on_connection_success():
	display_message("Loading world...", MessageTheme.SUCCESS)
	get_tree().change_scene_to_packed(level_to_load)


func _on_connection_failed():
	display_message("Connection failed", MessageTheme.ERROR)
	_disconnect_connection_signals()


func display_message(msg: String, message_theme: MessageTheme):
	match message_theme:
		MessageTheme.ERROR:
			message_label.modulate = Color.RED
		MessageTheme.SUCCESS:
			message_label.modulate = Color.GREEN
	message_label.text = msg
