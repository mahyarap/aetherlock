extends Control

@onready var title_button: Button = $Panel/TitleButton
@onready var quit_button: Button = $Panel/QuitButton


func _ready() -> void:
	title_button.pressed.connect(_on_title_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	title_button.grab_focus()


func _on_title_pressed() -> void:
	get_tree().paused = false

	var result: Error = get_tree().change_scene_to_file(
        "res://scenes/ui/title_screen.tscn"
	)

	if result != OK:
		push_error("Cannot open title: %s" % error_string(result))


func _on_quit_pressed() -> void:
	get_tree().quit()
