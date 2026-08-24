extends CharacterBody2D

signal health_depleted
signal damage_received(amount: float)
signal xp_gained(current_xp: int, required_xp: int)
signal level_up(new_level: int)

# Stats
var health = 100.0
var max_health = 100.0
var is_dead = false

# Movement Settings
const BASE_MOVE_SPEED = 250  # Base speed, upgradeable

# Knockback
var knockback_velocity = Vector2.ZERO
const KNOCKBACK_FORCE = 400.0
const KNOCKBACK_FRICTION = 600.0

# XP & Leveling
var current_xp: int = 0
var required_xp: int = 10  # Level 1→2 butuh 10 XP (konsisten dengan formula)
var level: int = 1

# SFX
var footstep_timer: float = 0.0
const FOOTSTEP_DELAY: float = 0.3

# Camera Shake
var shake_intensity: float = 0.0
const SHAKE_MAX: float = 15.0

func _ready():
	add_to_group("player")
	initialize_xp_bar()

func _physics_process(delta):
	if is_dead:
		return
	
	# Movement dengan base speed yang bisa di-upgrade
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Check apakah speed sudah di-upgrade, kalau belum pakai base speed
	var move_speed = get_meta("move_speed", BASE_MOVE_SPEED)
	
	# Mekanik melambat saat menembak
	var is_shooting = false
	if has_node("Gun"):
		is_shooting = $Gun.get_meta("is_shooting", false)
		
	if is_shooting:
		move_speed *= 0.80 # Kecepatan berkurang 20% — lebih aman dari sebelumnya (0.65)
		
	velocity = direction * move_speed + knockback_velocity
	move_and_slide()
	
	# Kurangi knockback secara bertahap
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
	
	# Animation & Sound
	if (velocity - knockback_velocity).length() > 0.0:
		%HappyBoo.play_walk_animation()
		
		# Footstep sound
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			SFX.play("footstep", -12.0, true) # Randomize pitch enabled
			footstep_timer = FOOTSTEP_DELAY
	else:
		%HappyBoo.play_idle_animation()
		footstep_timer = 0.0 # reset so first step is immediate
	
	# Damage handling
	const DAMAGE_RATE = 5.0  # Damage per second from mob contact
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		var raw_damage = DAMAGE_RATE * overlapping_mobs.size() * delta
		
		# Apply armor (damage reduction) from upgrades
		var damage_reduction = get_meta("damage_reduction", 0.0)
		var damage = raw_damage * (1.0 - damage_reduction)
		
		health -= damage
		damage_received.emit(damage)
		%HealthBar.value = health
		
		# Caveman shake screen!
		shake_intensity = SHAKE_MAX
		
		# Knockback player menjauh dari mob terdekat
		var nearest_mob = overlapping_mobs[0]
		var kb_dir = nearest_mob.global_position.direction_to(global_position)
		if kb_dir == Vector2.ZERO:
			kb_dir = Vector2.RIGHT.rotated(randf() * TAU)
		knockback_velocity = kb_dir * KNOCKBACK_FORCE
		
		if health <= 0.0:
			is_dead = true
			health_depleted.emit()

	# Caveman handle camera shake
	if shake_intensity > 0:
		shake_intensity = lerpf(shake_intensity, 0.0, 15.0 * delta)
		if has_node("Camera2D"):
			$Camera2D.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
			if shake_intensity < 0.1:
				shake_intensity = 0.0
				$Camera2D.offset = Vector2.ZERO

# XP Bar Functions
func initialize_xp_bar():
	if has_node("%XPBar"):
		%XPBar.min_value = 0
		%XPBar.max_value = required_xp
		%XPBar.value = current_xp

func gain_xp(amount: int):
	current_xp += amount
	xp_gained.emit(current_xp, required_xp)
	SFX.play("xp_pickup", -5.0)  # Play XP sound slightly quieter
	
	# Update XP bar
	update_xp_bar()
	
	# Check level up
	if current_xp >= required_xp:
		level_up_player()

func update_xp_bar():
	if not has_node("%XPBar"):
		return
	
	# Update bar smoothly dengan tween
	var tween = create_tween()
	tween.tween_property(%XPBar, "value", current_xp, 0.3)

func level_up_player():
	level += 1
	current_xp -= required_xp
	
	# Calculate new required XP
	required_xp = calculate_required_xp(level)
	
	# Reset bar max value
	%XPBar.max_value = required_xp
	
	# Emit signal
	level_up.emit(level)
	
	# Show level up effect
	play_level_up_effect()
	
	# Update bar
	update_xp_bar()
	
	# Pause dan show upgrade menu
	get_tree().paused = true
	show_upgrade_menu()
	
	# Check multiple level ups
	if current_xp >= required_xp:
		level_up_player()

func calculate_required_xp(lvl: int) -> int:
	# 5 + (level × 5): level 1→2=10, 2→3=15, 3→4=20, ...
	return 5 + (lvl * 5)

func play_level_up_effect():
	SFX.play("level_up")
	# XP Bar flash effect
	var tween = create_tween()
	tween.tween_property(%XPBar, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(%XPBar, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3)

func show_upgrade_menu():
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("show_level_up_menu"):
		game.show_level_up_menu()
