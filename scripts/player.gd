extends CharacterBody2D

const PROJECTILE_SCENE: PackedScene = preload(
	"res://scenes/combat/projectile.tscn"
)

@export_range(50.0, 600.0, 10.0) var move_speed: float = 260.0
@export_range(0.05, 1.0, 0.05) var fire_cooldown: float = 0.25

@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var attack_timer: Timer = $AttackCooldown

var aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	attack_timer.wait_time = fire_cooldown

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
	var new_aim_direction: Vector2 = global_position.direction_to(
		get_global_mouse_position()
	)
	if new_aim_direction != Vector2.ZERO:
		aim_direction = new_aim_direction
		aim_pivot.rotation = aim_direction.angle()
		
func _fire_projectile() -> void:
	var projectile: Projectile = (
			PROJECTILE_SCENE.instantiate() as Projectile
	)

	get_tree().current_scene.add_child(projectile)
	projectile.initialize(muzzle.global_position, aim_direction)
	attack_timer.start()
