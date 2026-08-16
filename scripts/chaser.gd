extends CharacterBody2D

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD,
}

@export_range(20.0, 400.0, 10.0) var move_speed: float = 110.0
@export_range(1, 20, 1) var contact_damage: int = 1
@export_range(0.2, 2.0, 0.1) var contact_cooldown: float = 0.8
@export_range(16.0, 64.0, 1.0) var stop_distance: float = 28.0
@export_range(4.0, 64.0, 1.0) var repath_distance: float = 16.0

@onready var body: ColorRect = $Body
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var contact_hitbox: Area2D = $ContactHitbox
@onready var damage_timer: Timer = $DamageCooldown
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var state_label: Label = $StateLabel

var target_body: CharacterBody2D
var contact_target: Hurtbox
var base_body_color: Color
var hit_tween: Tween
var last_target_position: Vector2
var has_navigation_target: bool = false
var current_state: State = State.IDLE


func _ready() -> void:
	base_body_color = body.color
	damage_timer.wait_time = contact_cooldown

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	contact_hitbox.area_entered.connect(_on_contact_area_entered)
	contact_hitbox.area_exited.connect(_on_contact_area_exited)
	hurtbox.damage_received.connect(_on_damage_received)
	health_component.died.connect(_on_died)

	_update_state_label()


func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE:
			_process_chase_state()
		State.ATTACK:
			_process_attack_state()
		State.DEAD:
			velocity = Vector2.ZERO
	if current_state != State.DEAD:
		move_and_slide()

func _process_chase_state() -> void:
	if not is_instance_valid(target_body):
			_change_state(State.IDLE)
			return

	if is_instance_valid(contact_target):
			_change_state(State.ATTACK)
			return

	if not _navigation_map_is_ready():
			velocity = Vector2.ZERO
			return

	_update_navigation_target()

	var target_distance: float = global_position.distance_to(
			target_body.global_position
	)

	if (
			target_distance <= stop_distance
			or navigation_agent.is_navigation_finished()
	):
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

	if not is_instance_valid(contact_target):
			_change_state(State.CHASE)
			return

	if damage_timer.is_stopped():
			_deal_contact_damage()


func _change_state(next_state: State) -> void:
	if current_state == next_state:
			return

	current_state = next_state
	_update_state_label()

	match current_state:
			State.IDLE:
					velocity = Vector2.ZERO
					has_navigation_target = false
			State.CHASE:
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
		State.CHASE :
			state_label.modulate = Color(1.0, 0.995, 0.299, 1.0)




func _navigation_map_is_ready() -> bool:
	var navigation_map: RID = navigation_agent.get_navigation_map()

	return (
		NavigationServer2D.map_get_iteration_id(navigation_map) > 0
	)


func _update_navigation_target() -> void:
	var current_target_position: Vector2 = target_body.global_position

	if (
		not has_navigation_target
		or last_target_position.distance_to(current_target_position)
			>= repath_distance
	):
		navigation_agent.target_position = current_target_position
		last_target_position = current_target_position
		has_navigation_target = true


func _deal_contact_damage() -> void:
	var hit_direction: Vector2 = global_position.direction_to(
		contact_target.global_position
	)

	contact_target.receive_damage(contact_damage, hit_direction)
	damage_timer.start()


func _on_detection_body_entered(body_entered: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body_entered is CharacterBody2D:
		target_body = body_entered as CharacterBody2D
		has_navigation_target = false
		_change_state(State.CHASE)


func _on_detection_body_exited(body_exited: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body_exited == target_body:
		target_body = null
		contact_target = null
		has_navigation_target = false
		navigation_agent.target_position = global_position
		_change_state(State.IDLE)


func _on_contact_area_entered(area: Area2D) -> void:
	if current_state == State.DEAD:
		return
	if area is Hurtbox:
		contact_target = area as Hurtbox
		if current_state == State.CHASE:
			_change_state(State.ATTACK)


func _on_contact_area_exited(area: Area2D) -> void:
	if current_state == State.DEAD:
		return
	if area != contact_target:
		return
	contact_target = null
	if is_instance_valid(target_body):
		_change_state(State.CHASE)
	else:
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
	contact_hitbox.set_deferred("monitoring", false)

	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()

	var death_tween: Tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(body, "scale", Vector2(1.5, 1.5), 0.15)
	death_tween.tween_property(body, "modulate:a", 0.0, 0.15)

	await death_tween.finished
	queue_free()
