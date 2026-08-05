extends CharacterBody2D

@export_range(50.0, 600.0, 10.0) var move_speed: float = 260.0

@onready var aim_pivot: Node2D = $AimPivot

var aim_direction: Vector2 = Vector2.RIGHT

func _process(delta: float) -> void:
	var new_aim_direction: Vector2 = global_position.direction_to(
		get_global_mouse_position()
	)
	if new_aim_direction != Vector2.ZERO:
		aim_direction = new_aim_direction
		aim_pivot.rotation = aim_direction.angle()

func _physics_process(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down",
	)
	velocity = input_direction * move_speed
	move_and_slide()
