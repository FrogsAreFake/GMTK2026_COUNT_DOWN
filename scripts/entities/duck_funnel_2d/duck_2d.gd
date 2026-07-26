extends Node2D

## Duck that walks in from the left, joins the line, stops under the funnel
## when it's its turn, gets fed feathers into its pillowcase, then walks
## away once full. If it waits stuck_timeout seconds without catching any
## feathers (e.g. the funnel gets stuck), it gives up and walks away early;
## the player is still rewarded proportionally to how full the pillowcase
## got, just without the full-pillowcase pose.

signal pillowcase_filled(duck: Node2D, feathers_by_tier: Dictionary, fill_ratio: float)
signal left_scene(duck: Node2D)

@export_group("Gameplay Settings")
@export var speed: float = 60.0
## Duck art (duck_1.png etc.) renders roughly 160 world units wide at the
## default Visual scale, so this needs to comfortably clear that width.
@export var min_spacing: float = 190.0
@export var pillowcase_capacity: int = 5
@export var despawn_x: float = 1400.0
## Added to pillowcase_capacity per level of the Pillow Density skill (id "4") purchased.
@export var capacity_bonus_per_level: int = 1

@export_group("Animation Settings")
## How long each walk-cycle frame (duck_1/2/3) is shown for, in seconds.
@export var walk_frame_interval: float = 0.15
## How long the duck stands still showing duck_4 (full pillowcase) before walking away.
@export var full_pause_duration: float = 1.0
## If the duck waits this long under the funnel without receiving a single
## new feather (e.g. the funnel gets stuck and never deploys), it gives up
## and walks away instead of waiting forever. The player is still rewarded,
## scaled down to the fraction of the pillowcase that got filled (even zero
## if nothing was collected), and the duck skips the full-pillowcase
## pose/pause since its pillowcase isn't actually full.
@export var stuck_timeout: float = 5.0

## Set by the spawner right after instantiation.
var duck_ahead: Node2D = null
var stop_x: float = 0.0
var funnel: Node = null

enum State { WALKING, WAITING, FULL_PAUSE, LEAVING }
var state: State = State.WALKING
var feathers_collected: int = 0
## Feathers collected into this pillowcase so far, keyed by tier (see
## GameManager.FEATHER_TIER_*), used to compute the tiered sale bonus.
var feathers_by_tier: Dictionary = {}

const WALK_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/duck_1.png"),
	preload("res://assets/textures/duck_2.png"),
	preload("res://assets/textures/duck_3.png"),
]
const FULL_TEXTURE: Texture2D = preload("res://assets/textures/duck_4.png")

## Pillowcase textures for the fill bands 0-20%, 20-40%, 40-60%, 60-80% and
## 80-100% of pillowcase_capacity, in that order.
const PILLOWCASE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/pillowcase_1.png"),
	preload("res://assets/textures/pillowcase_2.png"),
	preload("res://assets/textures/pillowcase_3.png"),
	preload("res://assets/textures/pillowcase_4.png"),
	preload("res://assets/textures/pillowcase_5.png"),
]

var _walk_frame: int = 0
var _walk_timer: float = 0.0
var _full_pause_timer: float = 0.0
## Time since this duck last made progress (caught a feather) while waiting.
## Reset to 0 whenever waiting starts or a feather is caught; if it reaches
## stuck_timeout, the duck gives up and leaves.
var _stuck_timer: float = 0.0

@onready var catcher: Area2D = $Catcher
@onready var pillowcase_collider: Area2D = $PillowcaseCollider
@onready var pillowcase_collider_shape: CollisionShape2D = $PillowcaseCollider/CollisionShape2D
@onready var duck_sprite: Sprite2D = $Visual/DuckSprite
@onready var pillowcase_sprite: Sprite2D = $Visual/Pillowcase


func _ready() -> void:
	catcher.body_entered.connect(_on_catcher_body_entered)
	pillowcase_capacity += SkillTreeManager.get_level("4") * capacity_bonus_per_level
	_update_pillowcase_visual()


func _process(delta: float) -> void:
	match state:
		State.WALKING:
			var moving := _process_walking(delta)
			if moving:
				_animate_walk(delta)
		State.WAITING:
			_process_waiting(delta)
		State.FULL_PAUSE:
			_process_full_pause(delta)
		State.LEAVING:
			_process_leaving(delta)
			_animate_walk(delta)


## Advances the duck while it's still walking toward the funnel, blocked by
## the duck ahead of it, etc. Returns true if the duck actually moved this
## frame (used to decide whether to play the walk-cycle animation — a
## stationary duck shouldn't look like it's still walking in place).
func _process_walking(delta: float) -> bool:
	if duck_ahead != null and is_instance_valid(duck_ahead):
		var max_x_from_pillowcase := _get_max_x_before_pillowcase_contact(duck_ahead)
		if position.x >= max_x_from_pillowcase:
			position.x = max_x_from_pillowcase
			return false
		if position.x + min_spacing >= duck_ahead.position.x:
			return false # Too close to the duck in front, hold position.
		if position.x + speed * delta > max_x_from_pillowcase:
			position.x = max_x_from_pillowcase
			return true

	if position.x >= stop_x:
		position.x = stop_x
		_start_waiting()
		return false

	position.x += speed * delta
	if position.x > stop_x:
		position.x = stop_x
	return true


func _process_waiting(delta: float) -> void:
	for body in catcher.get_overlapping_bodies():
		_try_collect_feather(body)
	if state != State.WAITING:
		return # A feather catch may have already moved us to FULL_PAUSE.

	_stuck_timer += delta
	if _stuck_timer >= stuck_timeout:
		_give_up()


func _process_full_pause(delta: float) -> void:
	_full_pause_timer -= delta
	if _full_pause_timer <= 0.0:
		_leave()


func _process_leaving(delta: float) -> void:
	position.x += speed * delta
	if position.x > despawn_x:
		left_scene.emit(self)
		queue_free()


func _start_waiting() -> void:
	state = State.WAITING
	_walk_frame = 0
	_stuck_timer = 0.0
	duck_sprite.texture = WALK_TEXTURES[0]
	if funnel:
		funnel.request_feed(self)


func _enter_full_pause() -> void:
	state = State.FULL_PAUSE
	_full_pause_timer = full_pause_duration
	duck_sprite.texture = FULL_TEXTURE


## Called when the duck has waited stuck_timeout seconds without catching a
## single new feather (e.g. the funnel is stuck and never deploys). The duck
## gives up waiting and walks away; the player is still rewarded, but only
## for the fraction of the pillowcase that got filled (fill_ratio), and the
## duck skips the full-pillowcase pose/pause since it isn't actually full.
func _give_up() -> void:
	var fill_ratio := 0.0
	if pillowcase_capacity > 0:
		fill_ratio = float(feathers_collected) / float(pillowcase_capacity)
	pillowcase_filled.emit(self, feathers_by_tier, fill_ratio)
	_leave()


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
	_stuck_timer = 0.0
	_update_pillowcase_visual()
	if feathers_collected >= pillowcase_capacity:
		pillowcase_filled.emit(self, feathers_by_tier, 1.0)
		_enter_full_pause()


## Cycles the duck's walk-cycle sprite (duck_1/2/3) on a short timer.
func _animate_walk(delta: float) -> void:
	_walk_timer += delta
	if _walk_timer < walk_frame_interval:
		return
	_walk_timer = 0.0
	_walk_frame = (_walk_frame + 1) % WALK_TEXTURES.size()
	duck_sprite.texture = WALK_TEXTURES[_walk_frame]


## Swaps the pillowcase sprite to match how full it currently is, changing
## at the 20/40/60/80/100% capacity thresholds.
func _update_pillowcase_visual() -> void:
	var fill_percent := 0.0
	if pillowcase_capacity > 0:
		fill_percent = float(feathers_collected) / float(pillowcase_capacity) * 100.0

	var stage := 0
	if fill_percent > 80.0:
		stage = 4
	elif fill_percent > 60.0:
		stage = 3
	elif fill_percent > 40.0:
		stage = 2
	elif fill_percent > 20.0:
		stage = 1

	pillowcase_sprite.texture = PILLOWCASE_TEXTURES[stage]


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
