extends Node

# https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

## Defines the default IP address when connecting via create_client
const DEFAULT_IP := "127.0.0.1" # localhost
## Defines default port for creating a server or connecting to a server
var DEFAULT_PORT := 8335 # BEES
## Defines the maximum amount of players a server will allow
var MAX_PLAYERS := 20

## Stores player data for all of the connected players
var players = {}
## Stores the current player data
var my_player_data: NetworkPlayerData = null

## Fires when a network peer has connected
signal player_connected(network_player)
## Fires when a network peer has disconnected
signal player_disconnected(id)
## Fires when we disconnect from server
signal server_disconnected

func _ready():
	_set_env_data()
	_connect_signals()

func create_server(port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	my_player_data = NetworkPlayerData.new(1)
	print("Server created")
	return Error.OK

## Creates client
func create_client(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	print("Client created")
	return Error.OK


## Terminates connection
func terminate() -> void:
	multiplayer.multiplayer_peer = null


func _set_env_data() -> void:
	var env_port = OS.get_environment('CB_PORT')
	if not env_port.is_empty():
		DEFAULT_PORT = env_port
	
	var env_max_players = OS.get_environment('CB_MAX_PLAYERS')
	if not env_port.is_empty():
		MAX_PLAYERS = env_max_players


func _connect_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connected_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


@rpc("any_peer", "reliable")
func _register_player(new_player_data_dict: Dictionary) -> void:
	var new_player_data = dict_to_inst(new_player_data_dict)
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_data
	player_connected.emit(new_player_data)


# A player has joined, send our player data to him
func _on_peer_connected(id: int):
	if not multiplayer.is_server():
		_register_player.rpc_id(id, inst_to_dict(my_player_data))


func _on_peer_disconnected(id: int):
	players.erase(id)
	player_disconnected.emit(id)
	

func _on_connected_to_server():
	my_player_data = NetworkPlayerData.new(multiplayer.get_unique_id())
	players[my_player_data.id] = my_player_data
	player_connected.emit(my_player_data)


func _on_connected_failed():
	terminate()


func _on_server_disconnected():
	terminate()
	server_disconnected.emit()
