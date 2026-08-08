extends CharacterBody2D

@export_range(20.0, 400.0, 10.0) var move_speed: float = 110.0
@export_range(1, 20, 1) var contact_damage: int = 1
@export_range(0.2, 2.0, 0.1) var contact_cooldown: float = 0.8
@export_range(16.0, 64.0, 1.0) var stop_distance: float = 28.0

@onready var body: ColorRect = $Body
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var contact_hitbox: Area2D = $ContactHitbox
@onready var damage_timer: Timer = $DamageCooldown

var target_body: CharacterBody2D
var contact_target: Hurtbox
var base_body_color: Color
var hit_tween: Tween


func _ready() -> void:
	base_body_color = body.color
	damage_timer.wait_time = contact_cooldown

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	contact_hitbox.area_entered.connect(_on_contact_area_entered)
	contact_hitbox.area_exited.connect(_on_contact_area_exited)
	hurtbox.damage_received.connect(_on_damage_received)
	health_component.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(target_body):
			var distance: float = global_position.distance_to(
					target_body.global_position
			)

			if distance > stop_distance:
					velocity = global_position.direction_to(
							target_body.global_position
					) * move_speed
			else:
					velocity = Vector2.ZERO
	else:
			velocity = Vector2.ZERO

	move_and_slide()

	if is_instance_valid(contact_target) and damage_timer.is_stopped():
			_deal_contact_damage()


func _deal_contact_damage() -> void:
	var hit_direction: Vector2 = global_position.direction_to(
			contact_target.global_position
	)

	contact_target.receive_damage(contact_damage, hit_direction)
	damage_timer.start()


func _on_detection_body_entered(body_entered: Node2D) -> void:
	if body_entered is CharacterBody2D:
			target_body = body_entered as CharacterBody2D


func _on_detection_body_exited(body_exited: Node2D) -> void:
	if body_exited == target_body:
			target_body = null


func _on_contact_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
			contact_target = area as Hurtbox


func _on_contact_area_exited(area: Area2D) -> void:
	if area == contact_target:
			contact_target = null


func _on_damage_received(
	_amount: int,
	_hit_direction: Vector2,
) -> void:
	if health_component.current_health == 0:
			return

	if hit_tween != null and hit_tween.is_valid():
			hit_tween.kill()

	body.color = Color.WHITE
	hit_tween = create_tween()
	hit_tween.tween_property(body, "color", base_body_color, 0.08)


func _on_died() -> void:
	velocity = Vector2.ZERO
	#set_physics_process(false)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hurtbox.set_deferred("monitorable", false)
	contact_hitbox.set_deferred("monitoring", false)

	if hit_tween != null and hit_tween.is_valid():
			hit_tween.kill()

	var death_tween: Tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(body, "scale", Vector2(1.5, 1.5), 0.15)
	death_tween.tween_property(body, "modulate:a", 0.0, 0.15)

	await death_tween.finished
	queue_free()
