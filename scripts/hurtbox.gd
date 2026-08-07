class_name Hurtbox
extends Area2D

@export var health_component: HealthComponent


func receive_damage(amount: int) -> void:
	if health_component == null:
			push_warning("%s has no HealthComponent" % name)
			return

	health_component.take_damage(amount)
