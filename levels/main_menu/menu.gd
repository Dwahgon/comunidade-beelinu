extends CenterContainer

var level_to_load = preload("res://levels/game.tscn")

@onready var create_room_message_label = %CreateRoomMessage
@onready var join_room_message_label = %JoinRoomMessage
@onready var room_list = %RoomList
@onready var name_input = %Name

var reloading = false

func _on_create_room_submit_pressed():
	# Validate name
	if not _validate_name(create_room_message_label):
		return

	# Try to create room
	var error = await MultiplayerManager.start_room(name_input.text)
	if error:
		display_message(create_room_message_label, "Error code %d" % error)
	else:
		get_tree().change_scene_to_packed(level_to_load)


func _on_join_room_button_clicked(room_data: Dictionary):
	# Validate name
	if not _validate_name(join_room_message_label):
		return

	# Try to create room
	var error = MultiplayerManager.join_room(name_input.text, room_data)
	if error:
		display_message(join_room_message_label, "Error code %d" % error)
	else:
		get_tree().change_scene_to_packed(level_to_load)


func _on_reload_room_list_pressed():
	if reloading:
		return
	display_message(join_room_message_label, "Atualizando...", MessageTheme.NORMAL)
	reloading = true

	# Request servers
	var error = SignalingServer.get_rooms()
	if error:
		display_message(join_room_message_label, "Error code %d" % error)
		return

	# Process response
	var res = await SignalingServer.request_completed
	if not res[1] == 200:
		display_message(join_room_message_label, "Error code %d" % res[1])
		return
	var room_data: Dictionary = JSON.parse_string(res[3].get_string_from_utf8())
	
	# Clear Room buttons
	for child in room_list.get_children():
		room_list.remove_child(child)
	
	# Add room buttons
	for room_id in room_data:
		var button = Button.new()
		button.text = str(room_id)
		button.pressed.connect(_on_join_room_button_clicked.bind(room_data[room_id]))
		room_list.add_child(button)
	
	display_message(join_room_message_label, "")
	reloading = false

enum MessageTheme {
	ERROR,
	SUCCESS,
	NORMAL
}

#func _on_client_submit_pressed():
##	if not _validate_name(client_message_label):
##		return
##
##	var ip = ip_input.text if not ip_input.text.is_empty() else MultiplayerManager.DEFAULT_IP
##	var port = int(port_input.text) if not port_input.text.is_empty() else MultiplayerManager.DEFAULT_PORT
##	var error = MultiplayerManager.create_client(name_input.text, ip, port)
##	if error:
##		display_message(client_message_label, "Error code %d" % error, MessageTheme.ERROR)
##	else:
##		display_message(client_message_label, "Connecting...", MessageTheme.SUCCESS)
##		_connect_connection_signals()


func _validate_name(message_label: Label):
	if (name_input.text.is_empty()):
		display_message(message_label, "Name must not be empty", MessageTheme.ERROR)
		return false
	return true

#
#func _connect_connection_signals():
#	MultiplayerManager.connection_failed.connect(_on_connection_failed)
#	MultiplayerManager.connection_success.connect(_on_connection_success)
#
#
#func _disconnect_connection_signals():
#	MultiplayerManager.connection_failed.disconnect(_on_connection_failed)
#	MultiplayerManager.connection_success.disconnect(_on_connection_success)
#
#
#func _on_connection_success():
#	display_message(client_message_label, "Loading world...", MessageTheme.SUCCESS)
#	get_tree().change_scene_to_packed(level_to_load)
#
#
#func _on_connection_failed():
#	display_message(client_message_label, "Connection failed", MessageTheme.ERROR)
#	_disconnect_connection_signals()
#
#
func display_message(label: Label, msg: String, message_theme: MessageTheme = MessageTheme.ERROR):
	match message_theme:
		MessageTheme.ERROR:
			label.modulate = Color.RED
		MessageTheme.SUCCESS:
			label.modulate = Color.GREEN
		MessageTheme.NORMAL:
			label.modulate = Color.WHITE
	label.text = msg
