class_name InteractionArea
extends Area2D

signal interacted

@export var prompt_text: String = "Interact"


func interact() -> void:
	interacted.emit()
