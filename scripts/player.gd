extends CharacterBody2D

const PROJECTILE_SCENE: PackedScene = preload(
    "res://scenes/combat/projectile.tscn"
)

@export_range(50.0, 600.0, 10.0) var move_speed: float = 260.0
@export_range(0.05, 1.0, 0.05) var fire_cooldown: float = 0.25
@export_range(300.0, 900.0, 10.0) var dodge_speed: float = 520.0
@export_range(0.05, 0.5, 0.01) var dodge_duration: float = 0.18
@export_range(0.1, 2.0, 0.05) var dodge_cooldown: float = 0.75

@onready var visuals: Node2D = $Visuals
@onready var body: ColorRect = $Visuals/Body
@onready var health_label: Label = $HealthLabel
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var attack_timer: Timer = $AttackCooldown
@onready var dodge_duration_timer: Timer = $DodgeDuration
@onready var dodge_cooldown_timer: Timer = $DodgeCooldown
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var aim_direction: Vector2 = Vector2.RIGHT
var last_move_direction: Vector2 = Vector2.RIGHT
var dodge_direction: Vector2 = Vector2.RIGHT

var is_dodging: bool = false
var base_body_color: Color
var hit_tween: Tween


func _ready() -> void:
	attack_timer.wait_time = fire_cooldown
	dodge_duration_timer.wait_time = dodge_duration
	dodge_cooldown_timer.wait_time = dodge_cooldown
	base_body_color = body.color

	dodge_duration_timer.timeout.connect(
			_on_dodge_duration_timeout
	)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	hurtbox.damage_received.connect(_on_damage_received)

	_update_health_label(
			health_component.current_health,
			health_component.max_health,
	)

	animation_player.play(&"idle")


func _process(_delta: float) -> void:
	_update_aim()

	if (
			not is_dodging
			and Input.is_action_pressed("attack")
			and attack_timer.is_stopped()
	):
			_fire_projectile()


func _physics_process(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down",
	)

	if input_direction != Vector2.ZERO:
			last_move_direction = input_direction.normalized()

	if (
			Input.is_action_just_pressed("dodge")
			and not is_dodging
			and dodge_cooldown_timer.is_stopped()
	):
			_start_dodge(input_direction)

	if is_dodging:
			velocity = dodge_direction * dodge_speed
	else:
			velocity = input_direction * move_speed
			_update_movement_animation(input_direction)

	move_and_slide()


func _start_dodge(input_direction: Vector2) -> void:
	if input_direction == Vector2.ZERO:
			dodge_direction = last_move_direction
	else:
			dodge_direction = input_direction.normalized()

	is_dodging = true
	hurtbox.set_invulnerable(true)
	body.modulate.a = 0.45

	animation_player.play(&"dodge", 0.03)
	dodge_duration_timer.start()
	dodge_cooldown_timer.start()


func _on_dodge_duration_timeout() -> void:
	is_dodging = false
	hurtbox.set_invulnerable(false)
	body.modulate.a = 1.0


func _update_movement_animation(
	input_direction: Vector2,
) -> void:
	if input_direction == Vector2.ZERO:
			_play_animation(&"idle")
	else:
			_play_animation(&"move")


func _play_animation(animation_name: StringName) -> void:
	if animation_player.current_animation == animation_name:
			return

	animation_player.play(animation_name, 0.08)


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
	hit_tween.tween_property(
			body,
			"color",
			base_body_color,
			0.1,
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
	health_label.text = "%d / %d" % [
			current_health,
			max_health,
	]


func _on_died() -> void:
	is_dodging = false
	dodge_duration_timer.stop()
	hurtbox.set_invulnerable(false)

	velocity = Vector2.ZERO
	set_process(false)
	set_physics_process(false)
	hurtbox.set_deferred("monitorable", false)

	animation_player.stop()
	visuals.scale = Vector2.ONE

	if hit_tween != null and hit_tween.is_valid():
			hit_tween.kill()

	body.color = base_body_color
	body.modulate = Color(0.35, 0.35, 0.35, 1.0)
	aim_pivot.visible = false
	health_label.text = "Offline"
