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
	var hit_direction: Vector2 = global_position.direction_to(
		hurtbox.global_position
	)
	if hurtbox.receive_damage(damage, hit_direction):
		hit_confirmed.emit()
