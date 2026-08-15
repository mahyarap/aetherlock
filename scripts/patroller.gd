extends CharacterBody2D

enum State {
	PATROL,
	PURSUE,
	ATTACK,
	DEAD,
}

const WORLD_COLLISION_MASK: int = 1

@export_range(20.0, 400.0, 10.0) var move_speed: float = 100.0
@export_range(1, 20, 1) var contact_damage: int = 1
@export_range(0.2, 2.0, 0.1) var contact_cooldown: float = 0.8
@export_range(4.0, 64.0, 1.0) var waypoint_reach_distance: float = 32.0
@export_range(4.0, 64.0, 1.0) var repath_distance: float = 16.0

@onready var body: ColorRect = $Body
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var contact_hitbox: Area2D = $ContactHitbox
@onready var damage_timer: Timer = $DamageCooldown
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var patrol_points: Node2D = $PatrolPoints
@onready var state_label: Label = $StateLabel

var player_in_range: CharacterBody2D
var target_body: CharacterBody2D
var contact_target: Hurtbox

var waypoint_positions: Array[Vector2] = []
var current_waypoint_index: int = 0

var last_navigation_target: Vector2
var has_navigation_target: bool = false

var base_body_color: Color
var hit_tween: Tween
var current_state: State = State.PATROL


func _ready() -> void:
	base_body_color = body.color
	damage_timer.wait_time = contact_cooldown

	for child: Node in patrol_points.get_children():
		if child is Marker2D:
			var waypoint: Marker2D = child as Marker2D
			waypoint_positions.append(waypoint.global_position)

	if waypoint_positions.is_empty():
		push_warning("%s has no patrol waypoints" % name)

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	contact_hitbox.area_entered.connect(_on_contact_area_entered)
	contact_hitbox.area_exited.connect(_on_contact_area_exited)
	hurtbox.damage_received.connect(_on_damage_received)
	health_component.died.connect(_on_died)

	_update_state_label()


func _physics_process(_delta: float) -> void:
	_update_perception()

	match current_state:
		State.PATROL:
			_process_patrol_state()
		State.PURSUE:
			_process_pursue_state()
		State.ATTACK:
			_process_attack_state()
		State.DEAD:
			velocity = Vector2.ZERO

	if current_state != State.DEAD:
		move_and_slide()


func _update_perception() -> void:
	if not is_instance_valid(player_in_range):
		if is_instance_valid(target_body):
			_lose_target()
		return

	if _has_line_of_sight(player_in_range):
		if target_body != player_in_range:
			target_body = player_in_range
			_change_state(State.PURSUE)
	elif is_instance_valid(target_body):
		_lose_target()


func _has_line_of_sight(player_body: CharacterBody2D) -> bool:
	var query: PhysicsRayQueryParameters2D = (
		PhysicsRayQueryParameters2D.create(
			global_position,
			player_body.global_position,
			WORLD_COLLISION_MASK,
		)
	)

	var result: Dictionary = (
		get_world_2d().direct_space_state.intersect_ray(query)
	)

	return result.is_empty()


func _process_patrol_state() -> void:
	if waypoint_positions.is_empty():
		velocity = Vector2.ZERO
		return

	var waypoint_position: Vector2 = (
		waypoint_positions[current_waypoint_index]
	)

	if (
		global_position.distance_to(waypoint_position)
		<= waypoint_reach_distance
	):
		print("GGGGGGGG")
		current_waypoint_index = (
			(current_waypoint_index + 1)
			% waypoint_positions.size()
		)
		has_navigation_target = false
		velocity = Vector2.ZERO
		return

	_follow_navigation_target(waypoint_position)


func _process_pursue_state() -> void:
	if not is_instance_valid(target_body):
		_change_state(State.PATROL)
		return

	if is_instance_valid(contact_target):
		_change_state(State.ATTACK)
		return

	_follow_navigation_target(target_body.global_position)


func _process_attack_state() -> void:
	velocity = Vector2.ZERO

	if not is_instance_valid(target_body):
		_change_state(State.PATROL)
		return

	if not is_instance_valid(contact_target):
		_change_state(State.PURSUE)
		return

	if damage_timer.is_stopped():
		_deal_contact_damage()


func _follow_navigation_target(desired_position: Vector2) -> void:
	if not _navigation_map_is_ready():
		velocity = Vector2.ZERO
		return

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


func _update_navigation_target(desired_position: Vector2) -> void:
	if (
		not has_navigation_target
		or last_navigation_target.distance_to(desired_position)
			>= repath_distance
	):
		navigation_agent.target_position = desired_position
		last_navigation_target = desired_position
		has_navigation_target = true


func _navigation_map_is_ready() -> bool:
	var navigation_map: RID = navigation_agent.get_navigation_map()

	return (
		NavigationServer2D.map_get_iteration_id(navigation_map) > 0
	)


func _lose_target() -> void:
	target_body = null
	has_navigation_target = false
	navigation_agent.target_position = global_position
	_change_state(State.PATROL)


func _deal_contact_damage() -> void:
	var hit_direction: Vector2 = global_position.direction_to(
			contact_target.global_position
	)

	contact_target.receive_damage(contact_damage, hit_direction)
	damage_timer.start()


func _change_state(next_state: State) -> void:
	if current_state == next_state:
		return

	current_state = next_state
	_update_state_label()

	match current_state:
		State.PATROL:
			velocity = Vector2.ZERO
			has_navigation_target = false
		State.PURSUE:
			has_navigation_target = false
		State.ATTACK:
			velocity = Vector2.ZERO
		State.DEAD:
			velocity = Vector2.ZERO


func _update_state_label() -> void:
	state_label.text = str(State.keys()[current_state])

	match current_state:
		State.PATROL:
			state_label.modulate = Color.GREEN
		State.PURSUE:
			state_label.modulate = Color.YELLOW
		State.ATTACK:
			state_label.modulate = Color.RED
		State.DEAD:
			state_label.modulate = Color.GRAY


func _on_detection_body_entered(body_entered: Node2D) -> void:
	if current_state == State.DEAD:
		return

	if body_entered is CharacterBody2D:
		player_in_range = body_entered as CharacterBody2D


func _on_detection_body_exited(body_exited: Node2D) -> void:
	if current_state == State.DEAD:
			return

	if body_exited != player_in_range:
			return

	player_in_range = null
	contact_target = null

	if body_exited == target_body:
			_lose_target()


func _on_contact_area_entered(area: Area2D) -> void:
	if current_state == State.DEAD:
			return

	if area is Hurtbox:
		contact_target = area as Hurtbox

		if (
			is_instance_valid(target_body)
			and current_state == State.PURSUE
		):
			_change_state(State.ATTACK)


func _on_contact_area_exited(area: Area2D) -> void:
	if current_state == State.DEAD:
			return

	if area != contact_target:
			return

	contact_target = null

	if is_instance_valid(target_body):
			_change_state(State.PURSUE)
	else:
			_change_state(State.PATROL)


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
			0.08,
	)


func _on_died() -> void:
	_change_state(State.DEAD)
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hurtbox.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)
	contact_hitbox.set_deferred("monitoring", false)

	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()

	var death_tween: Tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.15,
	)
	death_tween.tween_property(
		body,
		"scale",
		Vector2(1.5, 1.5),
		0.15,
	)

	await death_tween.finished
	queue_free()
