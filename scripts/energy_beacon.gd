extends Node2D

signal state_changed(is_active: bool)

@export var starts_active: bool = true
@export_range(0.2, 3.0, 0.1) var pulse_interval: float = 1.0
@export var active_color: Color = Color("4de1c1")
@export var inactive_color: Color = Color("263a43")

@onready var body: ColorRect = $Body
@onready var pulse_timer: Timer = $PulseTimer

var is_active: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_active = starts_active
	pulse_timer.wait_time = pulse_interval
	_update_visual()

func _update_visual() -> void:
	body.color = active_color if is_active else inactive_color

func _on_pulse_timer_timeout() -> void:
	is_active = not is_active
	_update_visual()
	state_changed.emit(is_active)
