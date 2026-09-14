class_name RelayPuzzle
extends Node2D

signal status_changed(message: String)
signal completed

enum State {
	WAITING_FOR_ALPHA,
	WAITING_FOR_BETA,
	COMPLETE,
}

const INACTIVE_COLOR := Color(0.18, 0.25, 0.38, 1.0)
const READY_COLOR := Color(0.30, 0.55, 0.86, 1.0)
const CHARGED_COLOR := Color(0.25, 0.85, 0.95, 1.0)
const COMPLETE_COLOR := Color(0.30, 0.90, 0.45, 1.0)
const INCOMPLETE_INDICATOR_COLOR := Color(0.55, 0.18, 0.20, 1.0)

@export var relay_alpha: InteractionArea
@export var relay_beta: InteractionArea
@export var relay_alpha_visual: ColorRect
@export var relay_beta_visual: ColorRect
@export var result_indicator: ColorRect

var state: State = State.WAITING_FOR_ALPHA


func _ready() -> void:
	if not _has_required_nodes():
			return

	relay_alpha.interacted.connect(
		_on_relay_alpha_interacted
	)
	relay_beta.interacted.connect(
		_on_relay_beta_interacted
	)
	_update_visuals()


func _has_required_nodes() -> bool:
	if (
		relay_alpha == null
		or relay_beta == null
		or relay_alpha_visual == null
		or relay_beta_visual == null
		or result_indicator == null
	):
		push_error("%s has incomplete puzzle references" % name)
		return false

	return true


func _on_relay_alpha_interacted() -> void:
	match state:
		State.WAITING_FOR_ALPHA:
			state = State.WAITING_FOR_BETA
			status_changed.emit(
                    "Alpha charged. Activate Beta."
		)
		State.WAITING_FOR_BETA:
			status_changed.emit(
                    "Alpha is already charged."
		)
		State.COMPLETE:
			status_changed.emit(
                    "Relay sequence already complete."
		)

	_update_visuals()


func _on_relay_beta_interacted() -> void:
	match state:
		State.WAITING_FOR_ALPHA:
			status_changed.emit(
                    "Wrong sequence. Activate Alpha first."
			)
		State.WAITING_FOR_BETA:
			state = State.COMPLETE
			status_changed.emit(
                    "Relay sequence complete."
			)
			_update_visuals()
			_disable_interactions()
			completed.emit()
			return
		State.COMPLETE:
			status_changed.emit(
                    "Relay sequence already complete."
			)

	_update_visuals()


func _update_visuals() -> void:
	match state:
		State.WAITING_FOR_ALPHA:
			relay_alpha_visual.color = READY_COLOR
			relay_beta_visual.color = INACTIVE_COLOR
			result_indicator.color = (
				INCOMPLETE_INDICATOR_COLOR
			)
		State.WAITING_FOR_BETA:
			relay_alpha_visual.color = CHARGED_COLOR
			relay_beta_visual.color = READY_COLOR
			result_indicator.color = (
				INCOMPLETE_INDICATOR_COLOR
			)
		State.COMPLETE:
			relay_alpha_visual.color = COMPLETE_COLOR
			relay_beta_visual.color = COMPLETE_COLOR
			result_indicator.color = COMPLETE_COLOR


func _disable_interactions() -> void:
	relay_alpha.set_deferred("monitorable", false)
	relay_beta.set_deferred("monitorable", false)
