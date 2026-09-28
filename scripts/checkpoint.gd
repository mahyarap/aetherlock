extends Node2D

signal activated

@onready var interaction_area: InteractionArea = $InteractionArea


func _ready() -> void:
	interaction_area.interacted.connect(_on_interacted)


func _on_interacted() -> void:
	activated.emit()
