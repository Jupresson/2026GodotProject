class_name Character
extends CharacterBody3D

# Signals emitted to notify other systems about character lifecycle and health changes.
signal spawned(character: Character)
signal died(character: Character)
signal enabled(character: Character)
signal disabled(character: Character)
signal health_changed(character: Character, new_health: float, old_health: float)
signal damaged(character: Character, amount: float, remaining_health: float)
signal healed(character: Character, amount: float, current_health: float)

# Editable defaults for health and startup behavior.
@export var max_health: float = 100.0
@export var starting_health: float = -1.0
@export var starts_enabled: bool = true
@export var can_take_damage: bool = true

# Runtime state.
var health: float = 100.0
var is_alive: bool = true
var is_enabled: bool = true

# Initialization lifecycle.
func _ready() -> void:
	max_health = maxf(max_health, 0.0)
	if starting_health < 0.0:
		health = max_health
	else:
		health = clampf(starting_health, 0.0, max_health)
	is_alive = health > 0.0
	set_enabled(starts_enabled, true)
	_on_spawn()
	spawned.emit(self)

# Public enable/disable API.
func enable() -> void:
	set_enabled(true)

func disable() -> void:
	set_enabled(false)

func set_enabled(value: bool, force: bool = false) -> void:
	if not force and is_enabled == value:
		return

	is_enabled = value
	process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED

	if is_enabled:
		_on_enable()
		enabled.emit(self)
	else:
		_on_disable()
		disabled.emit(self)

func set_can_take_damage(value: bool) -> void:
	can_take_damage = value

# Health change API.
func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	if not is_alive:
		return
	if not can_take_damage:
		return

	var old_health: float = health
	health = maxf(health - amount, 0.0)

	if is_equal_approx(old_health, health):
		return

	health_changed.emit(self, health, old_health)
	damaged.emit(self, amount, health)

	if health <= 0.0:
		is_alive = false
		_on_death()
		died.emit(self)

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	if not is_alive:
		return

	var old_health: float = health
	health = minf(health + amount, max_health)

	if is_equal_approx(old_health, health):
		return

	health_changed.emit(self, health, old_health)
	healed.emit(self, amount, health)

func revive(health_on_revive: float = -1.0) -> void:
	if is_alive:
		return

	is_alive = true
	if health_on_revive < 0.0:
		health = max_health
	else:
		health = clampf(health_on_revive, 0.0, max_health)

	var old_health: float = 0.0
	health_changed.emit(self, health, old_health)
	_on_spawn()
	spawned.emit(self)

func kill() -> void:
	if not is_alive:
		return

	var old_health: float = health
	health = 0.0
	is_alive = false
	health_changed.emit(self, health, old_health)
	_on_death()
	died.emit(self)

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return health / max_health

# Extension hooks for subclasses.
# Override to add spawn setup in child classes.
func _on_spawn() -> void:
	pass

# Override to add custom death behavior in child classes.
func _on_death() -> void:
	pass

# Override to add behavior when this character becomes enabled.
func _on_enable() -> void:
	pass

# Override to add behavior when this character becomes disabled.
func _on_disable() -> void:
	pass