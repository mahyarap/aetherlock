extends Node2D

@onready var status_label: Label = $StatusLabel
@onready var controls_label: Label = $ControlsLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	status_label.text = "Aetherlock labratory online"
	controls_label.text = "Move ..."
	print("Bootstrap scene ready")
