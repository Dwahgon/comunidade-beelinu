extends Control

const JOIN_BUTTON_SCENE = preload("res://join_button.tscn")

func _load_servers():
	if not visible:
		return
	var rooms_res = await BackendService.request_rooms()
	var servers = []
	servers.append_array(rooms_res["servers"])
	servers.append_array(rooms_res["temporaryServers"])
	
	for server in servers:
		var server_button = JOIN_BUTTON_SCENE.instantiate()
		server_button.text = server["server_name"]
		%RoomList.add_child(server_button)
	
