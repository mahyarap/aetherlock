extends Node2D

@onready var room: GameRoom = $LaboratoryRoom
@onready var player: CharacterBody2D = $Player
@onready var status_label: Label = $DebugUI/StatusLabel
@onready var controls_label: Label = $DebugUI/ControlsLabel


func _ready() -> void:
	room.status_changed.connect(_on_room_status_changed)
	player.global_position = room.get_player_spawn_position()

	status_label.text = "Aetherlock laboratory online"
	controls_label.text = "Move: WASD | Aim: Mouse | Dodge: Space"
	print("Bootstrap scene ready")


func _on_room_status_changed(message: String) -> void:
	status_label.text = message
