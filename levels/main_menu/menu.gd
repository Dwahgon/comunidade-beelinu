extends HBoxContainer


func _on_connect_server_prompt_connect_success() -> void:
	$ConnectServerPrompt.visible = false
	$Login.visible = true


func _on_login_login_success() -> void:
	$Login.visible = false
	$JoinRoom.visible = true


func _on_register_go_to_login() -> void:
	$Login.visible = true
	$Register.visible = false


func _on_login_go_to_register() -> void:
	$Login.visible = false
	$Register.visible = true


func _on_connect() -> void:
	$Login.visible = false
	$Register.visible = false


func _on_register_register_success() -> void:
	$Register.visible = false
	$JoinRoom.visible = true
