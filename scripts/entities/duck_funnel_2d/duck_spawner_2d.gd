extends Node2D

## Periodically spawns ducks so the line always looks indefinite. Each new
## duck is linked to the previously spawned duck ("duck_ahead") so the line
## self-organizes without a central queue manager: a duck only advances if
## it isn't too close to the duck ahead of it.

@export var duck_scene: PackedScene
@export var min_spawn_interval: float = 2.0
@export var max_spawn_interval: float = 3.5
## Flat payout for every filled pillowcase, regardless of feather tiers.
@export var flat_base_payout: int = 15
## Extra money paid per feather of each tier in the pillowcase, on top of
## flat_base_payout. Keyed by GameManager.FEATHER_TIER_* (0=common,
## 1=uncommon, 2=rare). Rarer feathers are worth progressively more so
## catching them during the run pays off in the shop.
@export var tier_bonus_per_feather: Dictionary = {0: 0, 1: 4, 2: 10}
## Node the spawned ducks are parented to. Falls back to this spawner's
## parent if left unset.
@export var duck_container_path: NodePath
@export var duck_stop_marker_path: NodePath
@export var funnel_path: NodePath

var duck_container: Node = null
var duck_stop_marker: Node2D = null
var funnel: Node = null

var _last_duck: Node2D = null
var _spawn_timer: Timer


func _ready() -> void:
	duck_container = get_node_or_null(duck_container_path)
	if duck_container == null:
		duck_container = get_parent()
	duck_stop_marker = get_node_or_null(duck_stop_marker_path)
	funnel = get_node_or_null(funnel_path)

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_spawn()
	_schedule_next_spawn()


func _schedule_next_spawn() -> void:
	_spawn_timer.start(randf_range(min_spawn_interval, max_spawn_interval))


func _on_spawn_timer_timeout() -> void:
	_spawn()
	_schedule_next_spawn()


func _spawn() -> void:
	if duck_scene == null or duck_container == null:
		return

	var duck := duck_scene.instantiate() as Node2D
	duck_container.add_child(duck)
	duck.global_position = global_position
	duck.duck_ahead = _last_duck
	duck.funnel = funnel
	if duck_stop_marker:
		duck.stop_x = duck_stop_marker.global_position.x
	duck.pillowcase_filled.connect(_on_pillowcase_filled)

	_last_duck = duck


## A duck's pillowcase reached capacity — sell the pillow for money. Payout
## is a flat base amount plus a bonus for each higher-tier feather it holds.
func _on_pillowcase_filled(_duck: Node2D, feathers_by_tier: Dictionary) -> void:
	var payout := flat_base_payout
	for tier in feathers_by_tier.keys():
		var count: int = feathers_by_tier[tier]
		var bonus: int = tier_bonus_per_feather.get(tier, 0)
		payout += bonus * count
	GameManager.add_money(payout)
