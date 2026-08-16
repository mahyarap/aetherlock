extends CharacterBody2D

enum State {
	IDLE,
	REPOSITION,
	ATTACK,
	DEAD,
}

const ENEMY_PROJECTILE_SCENE: PackedScene = preload(
	"res://scenes/combat/enemy_projectile.tscn"
)

@export_range(20.0, 400.0, 10.0) var move_speed: float = 90.0
@export_range(80.0, 240.0, 10.0) var minimum_distance: float = 160.0
@export_range(180.0, 500.0, 10.0) var maximum_distance: float = 300.0
@export_range(40.0, 300.0, 10.0) var retreat_distance: float = 180.0
@export_range(0.3, 3.0, 0.05) var fire_cooldown: float = 1.25
@export_range(4.0, 64.0, 1.0) var repath_distance: float = 16.0

@onready var body: ColorRect = $Body
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shoot_timer: Timer = $ShootCooldown
@onready var state_label: Label = $StateLabel

var target_body: CharacterBody2D
var base_body_color: Color
var hit_tween: Tween
var last_navigation_target: Vector2
var has_navigation_target: bool = false
var current_state: State = State.IDLE


func _ready() -> void:
	base_body_color = body.color
	shoot_timer.wait_time = fire_cooldown

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	hurtbox.damage_received.connect(_on_damage_received)
	health_component.died.connect(_on_died)

	_update_state_label()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(target_body):
			_update_aim()

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.REPOSITION:
			_process_reposition_state()
		State.ATTACK:
			_process_attack_state()
		State.DEAD:
			velocity = Vector2.ZERO
	if current_state != State.DEAD:
		move_and_slide()

func _process_reposition_state() -> void:
	if not is_instance_valid(target_body):
			_change_state(State.IDLE)
			return
	var distance: float = global_position.distance_to(
			target_body.global_position
	)
	if distance >= minimum_distance and distance <= maximum_distance:
			_change_state(State.ATTACK)
			return
	if not _navigation_map_is_ready():
			velocity = Vector2.ZERO
			return
	var desired_position: Vector2
	if distance < minimum_distance:
		var retreat_direction: Vector2 = (
			target_body.global_position.direction_to(global_position)
		)
		desired_position = (
			global_position + retreat_direction * retreat_distance
		)
	else:
		# NOTE: distance > maximum_distance
		desired_position = target_body.global_position

	desired_position = NavigationServer2D.map_get_closest_point(
		navigation_agent.get_navigation_map(),
		desired_position,
	)

	_update_navigation_target(desired_position)

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_path_position: Vector2 = (
		navigation_agent.get_next_path_position()
	)
	velocity = global_position.direction_to(
		next_path_position
	) * move_speed

func _process_attack_state() -> void:
	velocity = Vector2.ZERO

	if not is_instance_valid(target_body):
			_change_state(State.IDLE)
			return

	var distance: float = global_position.distance_to(
		target_body.global_position
	)

	if distance < minimum_distance or distance > maximum_distance:
		_change_state(State.REPOSITION)
		return

	if shoot_timer.is_stopped():
		_fire_projectile()

func _update_aim() -> void:
	var aim_direction: Vector2 = global_position.direction_to(
		target_body.global_position
	)
	aim_pivot.rotation = aim_direction.angle()

func _fire_projectile() -> void:
	var projectile: Projectile = (
		ENEMY_PROJECTILE_SCENE.instantiate() as Projectile
	)
	var fire_direction: Vector2 = global_position.direction_to(
		target_body.global_position
	)

	get_tree().current_scene.add_child(projectile)
	projectile.initialize(muzzle.global_position, fire_direction)
	shoot_timer.start()

func _update_navigation_target(desired_position: Vector2) -> void:
	if (
		not has_navigation_target
		or last_navigation_target.distance_to(desired_position)
			>= repath_distance
	):
		navigation_agent.target_position = desired_position
		last_navigation_target = desired_position
		has_navigation_target = true

func _change_state(next_state: State) -> void:
	if current_state == next_state:
			return

	current_state = next_state
	_update_state_label()

	match current_state:
			State.IDLE:
					velocity = Vector2.ZERO
					has_navigation_target = false
			State.REPOSITION:
					has_navigation_target = false
			State.ATTACK:
					velocity = Vector2.ZERO
			State.DEAD:
					velocity = Vector2.ZERO

func _update_state_label() -> void:
	state_label.text = str(State.keys()[current_state])
	match current_state:
		State.IDLE :
			state_label.modulate = Color(0.51, 0.499, 0.481, 1.0)
		State.ATTACK :
			state_label.modulate = Color(1.0, 0.0, 0.0, 1.0)
		State.DEAD :
			state_label.modulate = Color(0.228, 0.228, 0.211, 0.882)
		State.REPOSITION :
			state_label.modulate = Color(1.0, 0.995, 0.299, 1.0)

func _navigation_map_is_ready() -> bool:
	var navigation_map: RID = navigation_agent.get_navigation_map()

	return (
		NavigationServer2D.map_get_iteration_id(navigation_map) > 0
	)

func _on_detection_body_entered(body_entered: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body_entered is CharacterBody2D:
		target_body = body_entered as CharacterBody2D
		#has_navigation_target = false
		_change_state(State.REPOSITION)


func _on_detection_body_exited(body_exited: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body_exited == target_body:
		target_body = null
		has_navigation_target = false
		navigation_agent.target_position = global_position
		_change_state(State.IDLE)

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
	_change_state(State.DEAD)
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hurtbox.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)

	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()

	var death_tween: Tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	death_tween.tween_property(body, "scale", Vector2(1.5, 1.5), 0.15)

	await death_tween.finished
	queue_free()
