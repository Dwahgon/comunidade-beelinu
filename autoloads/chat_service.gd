extends Node

signal message_received(player_id, message)

@rpc("any_peer", "call_local", "reliable")
func send_message(message: String):
	var player_id = multiplayer.get_remote_sender_id()
	MultiplayerManager.multiplayer_log("ChatService", "%d: %s" % [player_id, message])
	message_received.emit(player_id, message)
