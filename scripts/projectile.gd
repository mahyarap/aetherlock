class_name Projectile
extends Area2D

const IMPACT_BURST_SCENE: PackedScene = preload(
    "res://scenes/combat/impact_burst.tscn"
)

@export_range(100.0, 1200.0, 25.0) var speed: float = 650.0
@export var impact_color: Color = Color(0.24, 1.0, 1.0)

@onready var lifetime_timer: Timer = $Lifetime

var direction: Vector2 = Vector2.RIGHT
var has_impacted: bool = false


func _ready() -> void:
	add_to_group(&"room_transient")


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
	_impact()


func _on_lifetime_timeout() -> void:
	queue_free()


func _on_hitbox_hit_confirmed() -> void:
	_impact()


func _impact() -> void:
	if has_impacted:
		return

	has_impacted = true
	set_physics_process(false)
	lifetime_timer.stop()
	_finish_impact.call_deferred()


func _finish_impact() -> void:
	var burst: CPUParticles2D = (
		IMPACT_BURST_SCENE.instantiate() as CPUParticles2D
	)

	get_tree().current_scene.add_child(burst)
	burst.global_position = global_position
	burst.color = impact_color
	burst.emitting = true
	burst.restart()

	queue_free()
