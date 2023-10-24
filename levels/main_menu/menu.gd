extends CenterContainer

var level_to_load = preload("res://levels/game.tscn")

@onready var server_message_label = %ServerMessage
@onready var client_message_label = %ClientMessage
@onready var name_input = %Name
@onready var ip_input = %IP
@onready var port_input = %Port

func _on_server_submit_pressed():
	if not _validate_name(server_message_label):
		return
	
	var error = MultiplayerManager.create_server(name_input.text)
	if error:
		server_message_label.text = "Error code %d" % error
	else:
		get_tree().change_scene_to_packed(level_to_load)

enum MessageTheme {
	ERROR,
	SUCCESS
}

func _on_client_submit_pressed():
	if not _validate_name(client_message_label):
		return
	
	var ip = ip_input.text if not ip_input.text.is_empty() else MultiplayerManager.DEFAULT_IP
	var port = int(port_input.text) if not port_input.text.is_empty() else MultiplayerManager.DEFAULT_PORT
	var error = MultiplayerManager.create_client(name_input.text, ip, port)
	if error:
		display_message(client_message_label, "Error code %d" % error, MessageTheme.ERROR)
	else:
		display_message(client_message_label, "Connecting...", MessageTheme.SUCCESS)
		_connect_connection_signals()


func _validate_name(message_label: Label):
	if (name_input.text.is_empty()):
		display_message(message_label, "Name must not be empty", MessageTheme.ERROR)
		return false
	return true


func _connect_connection_signals():
	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	MultiplayerManager.connection_success.connect(_on_connection_success)


func _disconnect_connection_signals():
	MultiplayerManager.connection_failed.disconnect(_on_connection_failed)
	MultiplayerManager.connection_success.disconnect(_on_connection_success)


func _on_connection_success():
	display_message(client_message_label, "Loading world...", MessageTheme.SUCCESS)
	get_tree().change_scene_to_packed(level_to_load)


func _on_connection_failed():
	display_message(client_message_label, "Connection failed", MessageTheme.ERROR)
	_disconnect_connection_signals()


func display_message(label: Label, msg: String, message_theme: MessageTheme):
	match message_theme:
		MessageTheme.ERROR:
			label.modulate = Color.RED
		MessageTheme.SUCCESS:
			label.modulate = Color.GREEN
	label.text = msg
