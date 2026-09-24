class_name Sentinel
extends CharacterBody2D

signal defeated

enum State {
	IDLE,
	WINDUP,
	RECOVERY,
	DEAD,
}

const ENEMY_PROJECTILE_SCENE: PackedScene = preload(
    "res://scenes/combat/enemy_projectile.tscn"
)

const BASE_COLOR := Color("#8844bb")
const WINDUP_COLOR := Color("#ffcf4a")
const PHASE_TWO_COLOR := Color("#d84b79")
const DEFEATED_COLOR := Color("#4cbb79")

@onready var body: ColorRect = $Body
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var windup_timer: Timer = $WindupTimer
@onready var volley_cooldown: Timer = $VolleyCooldown
@onready var state_label: Label = $StateLabel

var target: Player
var phase: int = 1
var current_state: State = State.IDLE


func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	windup_timer.timeout.connect(_on_windup_finished)
	volley_cooldown.timeout.connect(_on_cooldown_finished)
	_update_visual()


func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		return

	if not is_instance_valid(target):
		_set_state(State.IDLE)
		return

	aim_pivot.rotation = global_position.direction_to(
		target.global_position
	).angle()

	if current_state == State.IDLE:
		_start_windup()


func _start_windup() -> void:
	_set_state(State.WINDUP)
	windup_timer.start(0.65 if phase == 1 else 0.45)


func _on_windup_finished() -> void:
	if current_state != State.WINDUP:
		return

	if not is_instance_valid(target):
		_set_state(State.IDLE)
		return

	_fire_volley()
	_set_state(State.RECOVERY)
	volley_cooldown.start(1.6 if phase == 1 else 1.1)


func _fire_volley() -> void:
	var direction: Vector2 = global_position.direction_to(
		target.global_position
	)
	var shot_count: int = 3 if phase == 1 else 5
	var middle: float = float(shot_count - 1) / 2.0

	for index: int in range(shot_count):
		var angle_degrees: float = (float(index) - middle) * 18.0
		var shot_direction: Vector2 = direction.rotated(
			deg_to_rad(angle_degrees)
		)
		var projectile: Projectile = (
			ENEMY_PROJECTILE_SCENE.instantiate() as Projectile
		)

		get_tree().current_scene.add_child(projectile)
		projectile.initialize(
			muzzle.global_position,
			shot_direction
		)


func _on_cooldown_finished() -> void:
	if current_state != State.DEAD:
		_set_state(State.IDLE)


func _on_body_entered(other_body: Node2D) -> void:
	if current_state == State.DEAD:
		return

	if other_body is Player:
		target = other_body as Player


func _on_body_exited(other_body: Node2D) -> void:
	if current_state == State.DEAD or other_body != target:
		return

	target = null
	windup_timer.stop()
	volley_cooldown.stop()
	_set_state(State.IDLE)


func _on_health_changed(
	current_health: int,
	max_health: int,
) -> void:
	if current_health > 0 and current_health <= max_health / 2:
		phase = 2

	_update_visual()


func _on_died() -> void:
	_set_state(State.DEAD)
	windup_timer.stop()
	volley_cooldown.stop()
	detection_area.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	defeated.emit()


func _set_state(next_state: State) -> void:
	if current_state == next_state:
		return

	current_state = next_state
	_update_visual()


func _update_visual() -> void:
	state_label.text = "SENTINEL %d/12" % health_component.current_health

	match current_state:
		State.WINDUP:
			body.color = WINDUP_COLOR
		State.DEAD:
			body.color = DEFEATED_COLOR
		_:
			body.color = (
				PHASE_TWO_COLOR if phase == 2 else BASE_COLOR
			)
