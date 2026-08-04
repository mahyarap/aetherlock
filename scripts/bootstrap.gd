extends Node2D

@onready var status_label: Label = $StatusLabel
@onready var controls_label: Label = $ControlsLabel


func _ready() -> void:
	status_label.text = "Aetherlock laboratory online"
	controls_label.text = "Move: WASD"
	print("Bootstrap scene ready")
	

func _on_beacon_state_changed(is_active: bool) -> void:
	status_label.text = "Beacon active: %s" % is_active
