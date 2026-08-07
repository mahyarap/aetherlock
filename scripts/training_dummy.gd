extends Node2D

@onready var health_component: HealthComponent = $HealthComponent
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	_update_health_label(
			health_component.current_health,
			health_component.max_health,
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
	queue_free()
