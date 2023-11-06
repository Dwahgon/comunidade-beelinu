extends Node

const BASE_PORT := 8335
const MAX_PLAYERS := 32
const KEEP_ALIVE_TIMEOUT_SEC := 15
const ELECTION_TIMEOUT_SEC := 2
const RETRY_CREATE_ROOM_SEC := 2

## Stores player data for all of the connected players
var players = {}
## Stores the current player data
var my_player_data: NetworkPlayerData = null
var my_id: int = -1
var authority_id: int = -1
var room_id: int = -1
var next_player_id: int = -1
var host_buffer = {}


## Fires when a network peer has connected
signal player_connected(network_player)
## Fires when a network peer has disconnected
signal player_disconnected(network_player)
## Fires when we disconnect from server
signal server_disconnected
signal connection_failed
signal connection_success

func _ready():
	_connect_signals()
	_init_election_timer()
	_init_keep_alive_timer()
	get_tree().auto_accept_quit = false


func _compute_next_player_id():
	var peers = multiplayer.get_peers()
	if peers.size() == MAX_PLAYERS - 1:
		return -1
	var id = max(next_player_id % MAX_PLAYERS + 1, 1)
	while id == my_id or id in peers:
		id = id % MAX_PLAYERS + 1
	return id


func _calculate_next_peer_port(listening_peer: int = my_id, joining_peer: int = next_player_id):
	return BASE_PORT + (listening_peer-1) * MAX_PLAYERS + joining_peer - 2


func _listen_to_next_host():
	if next_player_id == -1:
		return
		
	var port = _calculate_next_peer_port()
	host_buffer[next_player_id] = ENetConnection.new()
	host_buffer[next_player_id].create_host_bound("*", port, 1)
	multiplayer_log("MultiplayerManager", 'Listening on port %d' % port)
	return true


func _connect_to_host(host_ip: String, host_port: int, host_id: int):
	host_buffer[host_id] = ENetConnection.new()
	host_buffer[host_id].create_host(1)
	host_buffer[host_id].connect_to_host(host_ip, host_port)
	multiplayer_log("MultiplayerManager", 'Connecting to host id %d on %s:%d' % [host_id, host_ip, host_port])


func _request_post_room():
	var error = SignalingServer.post_room(next_player_id, my_id)
	if error:
		return error
	
	# Receive response and extract room id
	var res = await SignalingServer.request_completed
	if res[0]:
		return res[0]
	if not res[1] == 200:
		print(res[3].get_string_from_utf8())
		return res[1]
	room_id = int(JSON.parse_string(res[3].get_string_from_utf8()))
	
	return error


func start_room(player_name: String) -> Error:
	var error := Error.OK
	my_id = 1
	authority_id = my_id

	# Create mesh peer
	var peer = ENetMultiplayerPeer.new()
	error = peer.create_mesh(my_id)
	if error:
		terminate()
		return error
	multiplayer.multiplayer_peer = peer
	next_player_id = _compute_next_player_id()
	
	# Request server creation in signaling server
	error = await _request_post_room()
	if error:
		terminate()
		return error
		
	# Initialize player data
	my_player_data = NetworkPlayerData.new(my_id)
	my_player_data.name = player_name
	
	# Create host and add it to buffer
	_listen_to_next_host()
	
	# Create player data
	_create_my_player(player_name)
	
	return error


func join_room(player_name: String, room_data: Dictionary) -> Error:
	var error := Error.OK
	my_id = room_data.nextPlayerId
	authority_id = room_data.authorityId
	
	# Create mesh peer
	var peer = ENetMultiplayerPeer.new()
	error = peer.create_mesh(my_id)
	if error:
		terminate()
		return error
	multiplayer.multiplayer_peer = peer
	
	# Try to connect to host
	_connect_to_host(room_data.ip, _calculate_next_peer_port(room_data.authorityId, my_id), room_data.authorityId)
	
	# Create player data
	_create_my_player(player_name)
	
	return error

func _process(_delta):
	if multiplayer.multiplayer_peer:
		for host_id in host_buffer:
			var host : ENetConnection = host_buffer[host_id]
			var event = host.service()
			if event[0] == host.EVENT_CONNECT:
				# Add host peer
				multiplayer.multiplayer_peer.add_mesh_peer(host_id, host)
				
				# Prepare for next player connection
				if my_id == authority_id: # We are the authority server and a player has connected, give that player the ip and ports of all the other peers, update signaling server data and listen to next player
					# Update signaling server
					next_player_id = _compute_next_player_id()
					SignalingServer.patch_room(room_id, {
						"nextPlayerId": next_player_id,
					})
					
					# Give the ips of the peers to the new player so he can connect to them
					var other_peers_ips = {}
					for peer_id in multiplayer.get_peers():
						if peer_id == host_id: # Don't send the player his own ip and port
							continue
						var peer_conn = multiplayer.multiplayer_peer.get_peer(peer_id)
						var peer_ip = peer_conn.get_remote_address()
						var peer_port = _calculate_next_peer_port(peer_id, host_id)
						other_peers_ips[peer_id] = "%s:%d" % [peer_ip, peer_port]
					_connect_to_other_peers.rpc_id(host_id, other_peers_ips, next_player_id)
				if host_id == next_player_id: # We're not the authority server, but a new player has connected. Increment next_player_id to listen to next player
					next_player_id = _compute_next_player_id()
				if host_id == authority_id: # We've connected to the authority server, emit connection success signal
					connection_success.emit()

				_listen_to_next_host()
				
				host_buffer.erase(host_id)
				multiplayer_log("MultiplayerManager", "Connected to host %d" % host_id)
			elif event[0] != host.EVENT_NONE:
				multiplayer_log("MultiplayerManager", "Host %d failed: %d" % [host_id, event[0]])
				if host_id == authority_id: # Failed to connect to authority, throw connection error
					connection_failed.emit()
				# Fix a bug
				if event[0] == -1:
					_listen_to_next_host()
				else:
					host_buffer.erase(host_id)
		multiplayer.multiplayer_peer.poll()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if my_id == authority_id and room_id >= 0:
			await terminate()
		get_tree().quit()


@rpc("any_peer", "reliable")
func _connect_to_other_peers(ips: Dictionary, next_id: int):
	# Connect to other peers
	for id in ips:
		var ip_port = ips[id].split(":")
		_connect_to_host(ip_port[0], int(ip_port[1]), id)
	
	# Listen for the next player
	next_player_id = next_id
	_listen_to_next_host()


func _create_my_player(player_name: String):
	my_player_data = NetworkPlayerData.new(my_id)
	my_player_data.name = player_name
	players[my_id] = my_player_data


## Terminates connection
func terminate() -> void:
	if my_id == authority_id and room_id >= 0:
		SignalingServer.delete_room(room_id)
		await SignalingServer.request_completed
		
	my_id = -1
	authority_id = -1
	room_id = -1
	next_player_id = -1
	
	multiplayer.multiplayer_peer = null
	my_player_data = null
	players.clear()


func _connect_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
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
	multiplayer_log("MultiplayerManager", "Peer connected: "+str(id))
	_register_player.rpc_id(id, inst_to_dict(my_player_data))


# A player has left, remove him from player list and start an election if he was the authority
func _on_peer_disconnected(id: int):
	player_disconnected.emit(players[id])
	players.erase(id)

	# We've reached max players and a player left, start listening to that port
	if next_player_id == -1:
		print("disconnected")
		next_player_id = _compute_next_player_id()
		_listen_to_next_host()
		# Update signaling server
		if my_id == authority_id:
			SignalingServer.patch_room(room_id, {
				"nextPlayerId": next_player_id,
			})
	
	# The peer that left was the authority, start an election
	if id == authority_id:
		_initialize_election()


func _on_connected_failed():
	print("MultiplayerManager - connection failed")
	terminate()
	connection_failed.emit()


func _on_server_disconnected():
	multiplayer_log("MultiplayerManager", "Disconnected from server")
	terminate()
	server_disconnected.emit()


func multiplayer_log(author: String, msg: String):
	print("[%d] %s - %s" % [my_id, author, msg])

func _init_keep_alive_timer():
	var timer := Timer.new()
	add_child(timer)
	timer.one_shot = false # Keep repeating
	timer.start(KEEP_ALIVE_TIMEOUT_SEC)
	timer.timeout.connect(func(): 
		if my_id != -1 and authority_id == my_id:
			SignalingServer.patch_keep_alive_room(room_id)
	)

#####################
## BULLY ALGORITHM ##
#####################

var _election_timer: Timer

# Create timer object
func _init_election_timer():
	_election_timer = Timer.new()
	_election_timer.name = "ElectionTimer"
	_election_timer.one_shot = true
	_election_timer.timeout.connect(_rpc_new_authority)
	add_child(_election_timer)

# Start an election
func _initialize_election():
	# Don't start election if it's already happening
	if not _election_timer.is_stopped():
		return
	
	multiplayer_log("NetworkManager", "Starting election")
	# Send election message to all peers and start timer
	_election.rpc()
	_election_timer.start(ELECTION_TIMEOUT_SEC)


# Call new authority
func _rpc_new_authority():
	_new_authority.rpc()


# Handle election message
@rpc("any_peer", "call_remote", "reliable")
func _election():
	multiplayer_log("NetworkManager", str(multiplayer.get_remote_sender_id()) + " --E-> " + str(my_id))
	if my_id < multiplayer.get_remote_sender_id(): # Punch the peer with larger id
		_punch.rpc_id(multiplayer.get_remote_sender_id())
		_initialize_election()

# Handle punch message
@rpc("any_peer", "call_remote", "reliable")
func _punch():
	multiplayer_log("NetworkManager", str(multiplayer.get_remote_sender_id()) + " --P-> " + str(my_id))
	# Stop election timer
	_election_timer.stop()


# Election timer has timeouted, means no peer has punched. We have been elected. Become authority
@rpc("any_peer", "call_local", "reliable")
func _new_authority():
	multiplayer_log("NetworkManager", str(multiplayer.get_remote_sender_id()) + " --A-> " + str(my_id))
	authority_id = multiplayer.get_remote_sender_id()
	if my_id == authority_id:
		var error = await _request_post_room()
		while error:
			multiplayer_log("MultiplayerManager", "Couldn't recreate room, trying again in %d seconds.." % RETRY_CREATE_ROOM_SEC)
			await get_tree().create_timer(RETRY_CREATE_ROOM_SEC).timeout
			error = await _request_post_room()
		_set_room_id.rpc(room_id)


@rpc("any_peer", "call_remote", "reliable")
func _set_room_id(new_room_id: int):
	if multiplayer.get_remote_sender_id() == authority_id:
		room_id = new_room_id
