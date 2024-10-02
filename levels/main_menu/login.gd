extends CenterContainer

signal login_success
signal go_to_register

func _on_button_pressed() -> void:
	%Loading.visible = true
	%LoginButton.visible = false
	var error = await BackendService.login(%Email.text, %Password.text)
	if error:
		%Loading.visible = false
		%LoginButton.visible = true
		%Error.text = "Erro: %d" % error
	else:
		login_success.emit()


func _on_go_to_register_meta_clicked(meta: Variant) -> void:
	go_to_register.emit()
