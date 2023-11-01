extends HTTPRequest

const DEFAULT_ROOM_SERVER_IP := "127.0.0.1"
const DEFAULT_ROOM_SERVER_PORT := 8080

# Signaling server comunication
var http_request: HTTPRequest
var server_ip := "127.0.0.1"
var server_port := 8080


func _ready():
	request_completed.connect(_log_request_response)
	
	server_ip = OS.get_environment("ROOM_SERVER_IP")
	server_ip = server_ip if not server_ip.is_empty() else DEFAULT_ROOM_SERVER_IP
	server_port = int(OS.get_environment("ROOM_SERVER_PORT"))
	server_port = server_port if server_port > 0 else DEFAULT_ROOM_SERVER_PORT


func _log_request_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	MultiplayerManager.multiplayer_log("SignalingServer", "Result: %d; Code: %d; Message: %s" % [result, response_code, body.get_string_from_utf8()])


func post_room(next_player_id: int, authority_id: int) -> Error:
	var body = {
		"nextPlayerId": next_player_id,
		"authorityId": authority_id,
	}
	return request(
		"http://%s:%s/rooms" % [server_ip, server_port], 
		["Content-Type: application/json"], HTTPClient.METHOD_POST, 
		JSON.stringify(body)
	)


func get_rooms() -> Error:
	return request(
		"http://%s:%s/rooms" % [server_ip, server_port], 
		PackedStringArray(), HTTPClient.METHOD_GET
	)


func get_room(room_id: int) -> Error:
	return request(
		"http://%s:%s/rooms/%d" % [server_ip, server_port, room_id], 
		PackedStringArray(), HTTPClient.METHOD_GET
	)



func patch_room(room_id: int, changes: Dictionary):
	return request(
		"http://%s:%s/rooms/%d" % [server_ip, server_port, room_id], 
		["Content-Type: application/json"], HTTPClient.METHOD_PATCH, 
		JSON.stringify(changes)
	)


func patch_keep_alive_room(room_id: int):
	return request(
		"http://%s:%s/rooms/%d/keep-alive" % [server_ip, server_port, room_id], 
		["Content-Type: application/json"], HTTPClient.METHOD_PATCH,
	)


func delete_room(room_id: int):
	return request(
		"http://%s:%s/rooms/%d" % [server_ip, server_port, room_id],
		[], HTTPClient.METHOD_DELETE
	)
