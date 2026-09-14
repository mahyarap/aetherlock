class_name Hazard
extends Node2D

@export_range(1, 100, 1) var damage: int = 1
@export var hitbox: Hitbox


func _ready() -> void:
	if hitbox == null:
		push_error("%s has no Hitbox assigned" % name)
		return

	hitbox.damage = damage
