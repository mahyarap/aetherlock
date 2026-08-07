class_name Hitbox
extends Area2D

signal hit_confirmed

@export_range(1, 100, 1) var damage: int = 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is not Hurtbox:
			return

	var hurtbox: Hurtbox = area as Hurtbox
	hurtbox.receive_damage(damage)
	hit_confirmed.emit()
