extends CharacterBody2D

const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")
const GEM_SCENE   = preload("res://xp_gem.tscn")

# ✨ Export variables - bisa diubah per scene!
@export var speed: float = 150.0
@export var health: int = 3
@export var xp_value: int = 1

var dead: bool = false  # guard biar tidak mati dua kali

# Data untuk debug — diisi oleh game.gd saat spawn
var _mob_type: String      = "?"
var _base_health: int      = 3      # HP sebelum semua scaling
var _base_speed: float     = 150.0  # speed sebelum semua scaling
var _fuzzy_mult: float     = 1.0    # fuzzy multiplier yang diterapkan
var _session_hp_mult: float  = 1.0  # hp_mult dari session
var _session_spd_mult: float = 1.0  # speed_mult dari session

# Debug label (hanya aktif di Debug mode)
var _debug_label: Label = null

@onready var player = get_tree().get_first_node_in_group("player")

var _frame_offset: int = 0

func _ready():
	_frame_offset = randi() % 4
	add_to_group("mobs")
	if has_node("%Slime"):
		%Slime.play_walk()
	
	if GameManager.is_debug():
		_create_debug_label()

func _physics_process(_delta):
	if player and is_instance_valid(player):
		var dist_sq = global_position.distance_squared_to(player.global_position)
		
		# Optimasi: Kalo mob jauh (>1200px), skip physics di 3 dari 4 frame
		if dist_sq > 1440000.0:
			if Engine.get_physics_frames() % 4 != _frame_offset:
				return
				
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()
	
	# Update label setiap frame mengikuti posisi mob
	if _debug_label and is_instance_valid(_debug_label):
		_update_debug_label()

func take_damage(amount: int = 1):
	if dead:
		return
	if has_node("%Slime"):
		%Slime.play_hurt()
	health -= amount
	if health <= 0:
		dead = true
		call_deferred("die")

func die():
	SFX.play("mob_die", -2.0, true)
	
	var smoke = SMOKE_SCENE.instantiate()
	smoke.global_position = global_position
	get_parent().call_deferred("add_child", smoke)
	
	var gem = GEM_SCENE.instantiate()
	gem.global_position = global_position
	gem.set_xp(xp_value)
	get_parent().call_deferred("add_child", gem)
	
	queue_free()

func update_difficulty(speed_multiplier: float):
	speed *= speed_multiplier

func update_fuzzy_difficulty(new_mult: float):
	if _fuzzy_mult == new_mult:
		return
		
	var old_max_hp = max(1, int(_base_health * _fuzzy_mult))
	var hp_pct = float(health) / float(old_max_hp)
	
	_fuzzy_mult = new_mult
	var new_max_hp = max(1, int(_base_health * _fuzzy_mult))
	
	# scale current health based on pct
	health = int(new_max_hp * hp_pct)
	speed = _base_speed * lerpf(1.0, _fuzzy_mult, 0.5)
	
	if _debug_label:
		_update_debug_label()

# ============================================
# PER-MOB DEBUG LABEL
# ============================================
func _create_debug_label():
	_debug_label = Label.new()
	_debug_label.z_index = 200   # di atas semua sprite

	# Font pixel agar konsisten dengan HUD
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")
	if pixel_font:
		_debug_label.add_theme_font_override("font", pixel_font)

	_debug_label.add_theme_font_size_override("font_size", 7)
	_debug_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_debug_label.add_theme_constant_override("outline_size", 5)

	# Letakkan di tengah-atas mob (menutupi sprite itu OK)
	_debug_label.position    = Vector2(-55, -30)
	_debug_label.custom_minimum_size = Vector2(110, 0)

	add_child(_debug_label)
	_update_debug_label()

func _update_debug_label():
	if not _debug_label:
		return

	# Warna teks berdasarkan sisa HP
	var hp_pct = float(health) / float(max(1, _base_health))
	var hp_color: Color
	if hp_pct > 0.6:
		hp_color = Color(0.3, 1.0, 0.45)   # hijau
	elif hp_pct > 0.3:
		hp_color = Color(1.0, 0.85, 0.2)   # kuning
	else:
		hp_color = Color(1.0, 0.3, 0.3)    # merah
	_debug_label.add_theme_color_override("font_color", hp_color)

	var max_hp = max(1, int(_base_health * _fuzzy_mult))

	_debug_label.text = (
		"[%s]\n"
		+ "HP: %d/%d\n"
		+ "  base: %d\n"
		+ "SPD: %.0f\n"
		+ "  base: %.0f\n"
		+ "MULT: x%.2f\n"
		+ "sess_hp: x%.1f\n"
		+ "sess_spd:x%.1f"
	) % [
		_mob_type,
		health, max_hp,
		_base_health,
		speed,
		_base_speed,
		_fuzzy_mult,
		_session_hp_mult,
		_session_spd_mult,
	]
