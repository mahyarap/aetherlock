extends Node2D

@onready var status_label: Label = $StatusLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	status_label.text = "Aetherlock labratory online"
	print("Bootstrap scene ready")
