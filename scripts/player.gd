extends CharacterBody2D

const PROJECTILE_SCENE: PackedScene = preload(
    "res://scenes/combat/projectile.tscn"
)

@export_range(50.0, 600.0, 10.0) var move_speed: float = 260.0
@export_range(0.05, 1.0, 0.05) var fire_cooldown: float = 0.25

@onready var body: ColorRect = $Body
@onready var health_label: Label = $HealthLabel
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var attack_timer: Timer = $AttackCooldown

var aim_direction: Vector2 = Vector2.RIGHT
var base_body_color: Color
var hit_tween: Tween


func _ready() -> void:
	attack_timer.wait_time = fire_cooldown
	base_body_color = body.color

	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	hurtbox.damage_received.connect(_on_damage_received)

	_update_health_label(
			health_component.current_health,
			health_component.max_health,
	)


func _process(_delta: float) -> void:
	_update_aim()

	if Input.is_action_pressed("attack") and attack_timer.is_stopped():
			_fire_projectile()


func _physics_process(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down",
	)

	velocity = input_direction * move_speed
	move_and_slide()


func _update_aim() -> void:
	var new_direction: Vector2 = global_position.direction_to(
			get_global_mouse_position()
	)

	if new_direction != Vector2.ZERO:
			aim_direction = new_direction
			aim_pivot.rotation = aim_direction.angle()


func _fire_projectile() -> void:
	var projectile: Projectile = (
			PROJECTILE_SCENE.instantiate() as Projectile
	)

	get_tree().current_scene.add_child(projectile)
	projectile.initialize(muzzle.global_position, aim_direction)
	attack_timer.start()


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
	hit_tween.tween_property(body, "color", base_body_color, 0.1)


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
	velocity = Vector2.ZERO
	set_process(false)
	set_physics_process(false)
	hurtbox.set_deferred("monitorable", false)

	if hit_tween != null and hit_tween.is_valid():
			hit_tween.kill()

	body.color = base_body_color
	body.modulate = Color(0.35, 0.35, 0.35, 1.0)
	aim_pivot.visible = false
	health_label.text = "Offline"
