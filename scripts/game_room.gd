class_name GameRoom
extends Node2D

signal status_changed(message: String)
signal transition_requested(destination_id: StringName)
signal energy_key_awarded

@export var room_title: String = "Room"
@export var player_spawn: Marker2D


func get_player_spawn_position() -> Vector2:
	if player_spawn == null:
		push_warning("%s has no PlayerSpawn assigned" % name)
		return global_position

	return player_spawn.global_position


func _on_beacon_state_changed(is_active: bool) -> void:
	if is_active:
		status_changed.emit("Beacon active")
	else:
		status_changed.emit("Beacon inactive")

func _on_puzzle_status_changed(message: String) -> void:
	status_changed.emit(message)

func _on_puzzle_completed() -> void:
	energy_key_awarded.emit()

func _on_door_access_denied(message: String) -> void:
	status_changed.emit(message)

func _on_door_transition_requested(destination_id: StringName) -> void:
	transition_requested.emit(destination_id)
