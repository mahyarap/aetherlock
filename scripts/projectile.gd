class_name Projectile
extends Area2D

@export_range(100.0, 1200.0, 25.0) var speed: float = 650.0

var direction: Vector2 = Vector2.RIGHT

func initialize(
	spawn_position: Vector2,
	travel_direction: Vector2,
) -> void:
	global_position = spawn_position
	direction = travel_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(_body: Node2D) -> void:
	queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_hitbox_hit_confirmed() -> void:
	queue_free()
