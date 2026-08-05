extends CharacterBody2D

@export_range(50.0, 600.0, 10.0) var move_speed: float = 260.0

func _physics_process(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
			"move_left",
			"move_right",
			"move_up",
			"move_down",
	)
	velocity = input_direction * move_speed
	move_and_slide()
