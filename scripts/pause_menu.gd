extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var volume_slider: HSlider = (
	$Overlay/MenuPanel/VolumeSlider
)
@onready var fullscreen_check: CheckButton = (
	$Overlay/MenuPanel/FullscreenCheck
)
@onready var resume_button: Button = (
	$Overlay/MenuPanel/ResumeButton
)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.hide()

	var master_bus: int = AudioServer.get_bus_index("Master")

	if AudioServer.is_bus_mute(master_bus):
		volume_slider.value = 0.0
	else:
		volume_slider.value = (
			db_to_linear(
				AudioServer.get_bus_volume_db(master_bus)
			) * 100.0
		)

	fullscreen_check.button_pressed = (
		DisplayServer.window_get_mode()
		== DisplayServer.WINDOW_MODE_FULLSCREEN
	)

	volume_slider.value_changed.connect(
		_on_volume_changed
	)
	fullscreen_check.toggled.connect(
		_on_fullscreen_toggled
	)
	resume_button.pressed.connect(
		_on_resume_pressed
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(value: bool) -> void:
	overlay.visible = value
	get_tree().paused = value

	if value:
		resume_button.grab_focus()
	else:
		resume_button.release_focus()


func _on_resume_pressed() -> void:
	_set_paused(false)


func _on_volume_changed(value: float) -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")

	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus, true)
		return

	AudioServer.set_bus_mute(master_bus, false)
	AudioServer.set_bus_volume_db(
		master_bus,
		linear_to_db(value / 100.0)
	)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)
