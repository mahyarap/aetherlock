class_name RoomDoor
extends Area2D

signal transition_requested(destination_id: StringName)

@export var destination_id: StringName

var has_requested_transition := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if has_requested_transition:
		return

	if body is not CharacterBody2D:
		return
	has_requested_transition = true
	set_deferred("monitoring", false)
	transition_requested.emit(destination_id)
