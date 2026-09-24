class_name RoomDoor
extends Area2D

signal transition_requested(destination_id: StringName)
signal access_denied(message: String)

const UNLOCKED_COLOR := Color(0.44, 1.0, 1.0, 1.0)
const LOCKED_COLOR := Color(1.0, 0.48, 0.20, 1.0)

@export var destination_id: StringName
@export var requires_energy_key: bool = false
@export var visual: ColorRect

var has_requested_transition := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if visual == null:
		push_error("%s has no Visual assigned" % name)
		return

	_update_visual()

func _on_body_entered(body: Node2D) -> void:
	if has_requested_transition:
		return

	if body is not Player:
		return

	var player := body as Player

	if requires_energy_key and not player.has_energy_key:
		access_denied.emit("Exit sealed. Energy key required.")
		return

	has_requested_transition = true
	visual.color = UNLOCKED_COLOR
	set_deferred("monitoring", false)
	transition_requested.emit(destination_id)

func _update_visual() -> void:
	if requires_energy_key:
		visual.color = LOCKED_COLOR
	else:
		visual.color = UNLOCKED_COLOR
