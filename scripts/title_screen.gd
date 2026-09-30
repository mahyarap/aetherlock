extends Control

@onready var play_button: Button = $Panel/PlayButton
@onready var quit_button: Button = $Panel/QuitButton


func _ready() -> void:
	if GameSave.load_checkpoint().is_empty():
		play_button.text = "Start"
	else:
		play_button.text = "Continue"

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().paused = false

	var result: Error = get_tree().change_scene_to_file(
        "res://scenes/world/bootstrap.tscn"
	)

	if result != OK:
		push_error("Cannot start game: %s" % error_string(result))


func _on_quit_pressed() -> void:
	get_tree().quit()
