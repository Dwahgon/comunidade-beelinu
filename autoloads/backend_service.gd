extends HTTPRequest

class Account:
	var user_id: int
	var username: String

var selected_server_url = ""
var token = ""
var connected_account: Account = null

func send_ping():
	var request_error = request(selected_server_url+"/ping")
	if request_error:
		return request_error
	var response = await request_completed
	if response[0]:
		return response[0]
	if response[1] != 200:
		return response[1]
	return Error.OK


func connect_to_server(address: String):
	selected_server_url = address
	var connect_error = await send_ping()
	if connect_error:
		selected_server_url = ""
	return connect_error

func request_register(email: String, username: String, password: String):
	var request_error = request(selected_server_url+"/player", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"email": email, "username": username, "password": password}))
	if request_error:
		return {"error": request_error, "result": null}
	var response = await request_completed
	if response[0]:
		return {"error": response[0], "result": JSON.parse_string(response[3].get_string_from_utf8())}
	if response[1] != 200:
		return {"error": response[1], "result": JSON.parse_string(response[3].get_string_from_utf8())}
	return {"error": Error.OK, "result": JSON.parse_string(response[3].get_string_from_utf8())}

func request_login(email: String, password: String):
	var body = JSON.stringify({"email": email, "password": password})
	var request_error = request(selected_server_url+"/auth/player", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if request_error:
		return {"error": request_error, "token": ""}
	var response = await request_completed
	if response[0]:
		return {"error": response[0], "token": ""}
	if response[1] != 200:
		return {"error": response[1], "token": ""}
	return {"error": Error.OK, "token": JSON.parse_string(response[3].get_string_from_utf8())["token"]}

func login(email: String, password: String):
	var login_result = await request_login(email, password)
	if login_result["error"]:
		return login_result["error"]
	token = login_result["token"]
	return Error.OK

func request_rooms():
	var request_error = request(selected_server_url+"/server")
	if request_error:
		return {"error": request_error, "servers": [], "temporaryServers": []}
	var response = await request_completed
	if response[0]:
		return {"error": response[0], "servers": [], "temporaryServers": []}
	if response[1] != 200:
		return {"error": response[1], "servers": [], "temporaryServers": []}
		
	var body = JSON.parse_string(response[3].get_string_from_utf8())
	return {"error": Error.OK, "servers": body["servers"], "temporaryServers": body["temporaryServers"]}
