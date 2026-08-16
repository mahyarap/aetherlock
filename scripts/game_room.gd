class_name GameRoom
extends Node2D

signal status_changed(message: String)

@export var player_spawn: Marker2D


func get_player_spawn_position() -> Vector2:
	if player_spawn == null:
			push_warning("%s has no PlayerSpawn assigned" % name)
			return global_position

	return player_spawn.global_position


func _on_beacon_state_changed(is_active: bool) -> void:
	status_changed.emit("Beacon active: %s" % is_active)
