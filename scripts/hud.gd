class_name GameHUD
extends CanvasLayer

@onready var room_label: Label = $TopPanel/RoomLabel
@onready var health_label: Label = $TopPanel/HealthLabel
@onready var key_label: Label = $TopPanel/KeyLabel
@onready var status_label: Label = $TopPanel/StatusLabel


func bind_player(player: Player) -> void:
	player.health_component.health_changed.connect(
		_on_health_changed
	)
	player.energy_key_changed.connect(
		_on_energy_key_changed
	)

	_on_health_changed(
		player.health_component.current_health,
		player.health_component.max_health
	)
	_on_energy_key_changed(player.has_energy_key)


func show_room(title: String) -> void:
	room_label.text = title
	status_label.text = ""


func show_status(message: String) -> void:
	status_label.text = message


func _on_health_changed(
	current_health: int,
	max_health: int,
) -> void:
	health_label.text = "Health: %d / %d" % [
		current_health,
		max_health,
	]


func _on_energy_key_changed(has_energy_key: bool) -> void:
	if has_energy_key:
		key_label.text = "Energy key: acquired"
	else:
		key_label.text = "Energy key: missing"
