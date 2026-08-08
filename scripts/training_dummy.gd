extends Node2D

@export var flash_color: Color = Color.WHITE
@export_range(0.05, 0.3, 0.01) var hit_duration: float = 0.12
@export_range(0.0, 12.0, 1.0) var visual_recoil: float = 6.0

@onready var body: ColorRect = $Body
@onready var health_label: Label = $HealthLabel
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox

var base_body_color: Color
var base_body_position: Vector2
var feedback_tween: Tween


func _ready() -> void:
	base_body_color = body.color
	base_body_position = body.position

	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	hurtbox.damage_received.connect(_on_damage_received)

	_update_health_label(
			health_component.current_health,
			health_component.max_health,
	)


func _on_damage_received(
	_amount: int,
	hit_direction: Vector2,
) -> void:
	if health_component.current_health == 0:
			return

	if feedback_tween != null and feedback_tween.is_valid():
			feedback_tween.kill()

	body.color = flash_color
	body.scale = Vector2(1.2, 0.8)
	body.position = base_body_position + hit_direction * visual_recoil

	feedback_tween = create_tween()
	feedback_tween.set_parallel(true)
	feedback_tween.tween_property(
			body,
			"color",
			base_body_color,
			hit_duration,
	)
	feedback_tween.tween_property(
			body,
			"scale",
			Vector2.ONE,
			hit_duration,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(
			body,
			"position",
			base_body_position,
			hit_duration,
	)


func _on_health_changed(
	current_health: int,
	max_health: int,
) -> void:
	_update_health_label(current_health, max_health)


func _update_health_label(
	current_health: int,
	max_health: int,
) -> void:
	health_label.text = "%d / %d" % [current_health, max_health]

func _on_died() -> void:
	hurtbox.set_deferred("collision_layer", 0)

	if feedback_tween != null and feedback_tween.is_valid():
			feedback_tween.kill()

	var death_tween: Tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(
			body,
			"scale",
			Vector2(1.5, 1.5),
			0.18,
	)
	death_tween.tween_property(
			body,
			"modulate:a",
			0.0,
			0.18,
	)
	death_tween.tween_property(
			health_label,
			"modulate:a",
			0.0,
			0.18,
	)

	await death_tween.finished
	queue_free()
