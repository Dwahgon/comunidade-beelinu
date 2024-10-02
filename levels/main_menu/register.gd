extends CenterContainer

signal register_success
signal go_to_login

func _on_button_pressed() -> void:
	%Loading.visible = true
	%RegisterButton.visible = false
	var result = await BackendService.request_register(%Email.text, %Username.text, %Password.text)
	if result["error"]:
		%Loading.visible = false
		%RegisterButton.visible = true
		%Error.text = "Erro"
	else:
		await BackendService.login(%Email.text, %Password.text)
		register_success.emit()


func _on_go_to_register_meta_clicked(meta: Variant) -> void:
	go_to_login.emit()
