class_name Hurtbox
extends Area2D

signal damage_received(amount: int, hit_direction: Vector2)

@export var health_component: HealthComponent


func receive_damage(amount: int, hit_direction: Vector2) -> bool:
	if health_component == null:
		push_warning("%s has no HealthComponent" % name)
		return false

	var damage_applied: bool = health_component.take_damage(amount)
	if damage_applied:
		damage_received.emit(amount, hit_direction)
	return damage_applied
