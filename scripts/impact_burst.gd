extends CPUParticles2D


func _ready() -> void:
	add_to_group(&"room_transient")
	finished.connect(queue_free)
