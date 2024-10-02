extends CenterContainer

signal connect_success

func _on_connect_server_button_pressed() -> void:
	var address_input = %AddressInput
	%ConnectServerButton.visible = false
	%ConnectingLabel.visible = true
	var error = await BackendService.connect_to_server(%AddressInput.text)
	if error:
		%ConnectServerButton.visible = true
		%ConnectingLabel.visible = false
		%ConnectError.visible = true
		%ConnectError.text = "Erro ao conectar-se ao servidor: %s" % get_error_message(error)
	else:
		connect_success.emit()

func get_error_message(error_code: int):
	match error_code:
		Error.ERR_INVALID_PARAMETER:
			return "URL Inválido"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Não foi possível se conectar ao servidor"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Não foi possível resolver a URL"
		HTTPClient.RESPONSE_NOT_FOUND:
			return "URL não aponta para um servidor válido"
	return str(error_code)
