extends HTTPRequest


# Signaling server comunication
var http_request: HTTPRequest
var server_ip = "127.0.0.1"
var server_port = 8080


func _ready():
	request_completed.connect(_log_request_response)


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


func patch_room(room_id: int, changes: Dictionary):
	return request(
		"http://%s:%s/rooms/%d" % [server_ip, server_port, room_id], 
		["Content-Type: application/json"], HTTPClient.METHOD_PATCH, 
		JSON.stringify(changes)
	)
