extends Control

const JOIN_BUTTON_SCENE = preload("res://join_button.tscn")

func _load_servers():
	if not visible:
		return
	var rooms_res = await BackendService.request_rooms()
	var servers = []
	servers.append_array(rooms_res["servers"])
	servers.append_array(rooms_res["temporaryServers"])
	for filho in %RoomList.get_children():
		filho.queue_free()
		
	for server in servers:
		var server_button = JOIN_BUTTON_SCENE.instantiate()
		server_button.text = server["server_name"]
		%RoomList.add_child(server_button)
	

func _on_reload_button_pressed() -> void:
	print("Carregando servidores...")
	_load_servers()
