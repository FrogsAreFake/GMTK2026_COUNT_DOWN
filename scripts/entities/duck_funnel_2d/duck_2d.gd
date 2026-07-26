extends Node2D

## Duck that walks in from the left, joins the line, stops under the funnel
## when it's its turn, gets fed feathers into its pillowcase, then walks
## away once full. Waits indefinitely under the funnel if no feathers are
## available (the shop runs continuously, so feathers eventually arrive).

signal pillowcase_filled(duck: Node2D, feathers_by_tier: Dictionary)
signal left_scene(duck: Node2D)

@export_group("Gameplay Settings")
@export var speed: float = 60.0
@export var min_spacing: float = 72.0
@export var pillowcase_capacity: int = 5
@export var despawn_x: float = 1400.0
## Added to pillowcase_capacity per level of the Firmer Pillows skill (id "4") purchased.
@export var capacity_bonus_per_level: int = 1

## Set by the spawner right after instantiation.
var duck_ahead: Node2D = null
var stop_x: float = 0.0
var funnel: Node = null

enum State { WALKING, WAITING, LEAVING }
var state: State = State.WALKING
var feathers_collected: int = 0
## Feathers collected into this pillowcase so far, keyed by tier (see
## GameManager.FEATHER_TIER_*), used to compute the tiered sale bonus.
var feathers_by_tier: Dictionary = {}

@onready var catcher: Area2D = $Catcher
@onready var pillowcase_collider: Area2D = $PillowcaseCollider
@onready var pillowcase_collider_shape: CollisionShape2D = $PillowcaseCollider/CollisionShape2D


func _ready() -> void:
	catcher.body_entered.connect(_on_catcher_body_entered)
	pillowcase_capacity += SkillTreeManager.get_level("4") * capacity_bonus_per_level


func _process(delta: float) -> void:
	match state:
		State.WALKING:
			_process_walking(delta)
		State.WAITING:
			_process_waiting(delta)
		State.LEAVING:
			_process_leaving(delta)


func _process_walking(delta: float) -> void:
	if duck_ahead != null and is_instance_valid(duck_ahead):
		var max_x_from_pillowcase := _get_max_x_before_pillowcase_contact(duck_ahead)
		if position.x >= max_x_from_pillowcase:
			position.x = max_x_from_pillowcase
			return
		if position.x + min_spacing >= duck_ahead.position.x:
			return # Too close to the duck in front, hold position.
		if position.x + speed * delta > max_x_from_pillowcase:
			position.x = max_x_from_pillowcase
			return

	if position.x >= stop_x:
		position.x = stop_x
		_start_waiting()
		return

	position.x += speed * delta
	if position.x > stop_x:
		position.x = stop_x


func _process_waiting(delta: float) -> void:
	for body in catcher.get_overlapping_bodies():
		_try_collect_feather(body)
	if feathers_collected >= pillowcase_capacity:
		_leave()


func _process_leaving(delta: float) -> void:
	position.x += speed * delta
	if position.x > despawn_x:
		left_scene.emit(self)
		queue_free()


func _start_waiting() -> void:
	state = State.WAITING
	if funnel:
		funnel.request_feed(self)


func _leave() -> void:
	if state == State.LEAVING:
		return
	state = State.LEAVING
	if funnel:
		funnel.release_feed(self)


func _on_catcher_body_entered(body: Node) -> void:
	_try_collect_feather(body)


func _try_collect_feather(body: Node) -> void:
	if state != State.WAITING:
		return
	if not body.is_in_group("feather"):
		return
	if not is_instance_valid(body) or body.is_queued_for_deletion():
		return

	feathers_collected += 1
	var tier: int = body.get("tier") if body.get("tier") != null else 0
	feathers_by_tier[tier] = feathers_by_tier.get(tier, 0) + 1
	body.queue_free()
	if feathers_collected >= pillowcase_capacity:
		pillowcase_filled.emit(self, feathers_by_tier)
		_leave()


func _get_max_x_before_pillowcase_contact(duck_in_front: Node2D) -> float:
	if not duck_in_front.has_method("get_pillowcase_left_edge"):
		return INF
	return duck_in_front.call("get_pillowcase_left_edge") - _get_pillowcase_half_width()


func _get_pillowcase_half_width() -> float:
	var shape := pillowcase_collider_shape.shape as RectangleShape2D
	if shape == null:
		return 0.0
	return shape.size.x * 0.5


func get_pillowcase_left_edge() -> float:
	return pillowcase_collider.global_position.x - _get_pillowcase_half_width()
