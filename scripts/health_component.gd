class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal died

@export_range(1, 1000, 1) var max_health: int = 3

var current_health: int


func _ready() -> void:
	current_health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
			return

	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
			died.emit()
