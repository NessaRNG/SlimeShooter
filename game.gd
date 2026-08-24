extends Node2D

var player = null
var upgrade_menu = null
var pause_menu = null
var game_over_screen = null

# Mob management
var total_mob_count: int = 0
const MAX_TOTAL_MOBS: int = 60 # Mobile optimized (was 100)

# Track stats
var survival_time: float = 0.0
var total_kills: int = 0
var game_started: bool = false

# ============================================
# FUZZY DDA SYSTEM
# ============================================
var fuzzy_dda = null
var fuzzy_difficulty: float = 1.0  # Current difficulty multiplier (0.5 – 1.5)
var fuzzy_eval_timer: float = 0.0
const FUZZY_EVAL_INTERVAL: float = 4.0  # Evaluate setiap 4 detik (lebih responsif)

# Performance tracking for fuzzy input
var kills_window: Array = []      # Timestamps of recent kills
var damage_window: Array = []     # [timestamp, amount] of recent damage
const PERFORMANCE_WINDOW: float = 30.0  # Window 30 detik terakhir

# Track total difficulty for average calculation
var fuzzy_difficulty_sum: float = 0.0
var fuzzy_difficulty_count: int = 0

# ============================================
# DEBUG OVERLAY
# ============================================
var debug_panel = null
var debug_labels: Dictionary = {}  # key → Label node
# Store last fuzzy inputs for display
var _dbg_health_ratio: float = 0.0
var _dbg_kill_rate: float = 0.0
var _dbg_damage_rate: float = 0.0
var _dbg_h_low: float = 0.0
var _dbg_h_med: float = 0.0
var _dbg_h_high: float = 0.0
var _dbg_k_low: float = 0.0
var _dbg_k_med: float = 0.0
var _dbg_k_high: float = 0.0
var _dbg_d_low: float = 0.0
var _dbg_d_med: float = 0.0
var _dbg_d_high: float = 0.0
var _dbg_eval_count: int = 0
var _dbg_last_output: String = ""

# ============================================
# FUZZY TESTER PANEL vars
# ============================================
var fuzzy_tester_panel = null
var fuzzy_tester_visible: bool = false
var _ft_sliders: Dictionary = {}
var _ft_val_labels: Dictionary = {}
var _ft_result_labels: Dictionary = {}
var _ft_expected_idx: int = 2   # 0=VE 1=E 2=N 3=H 4=VH (default: Normal)
var _ft_diff_buttons: Array = []
var _ft_match_label: Label = null
var _ft_test_log: Array = []
var _ft_log_vbox: VBoxContainer = null
var _ft_last_result: float = -1.0
var _ft_last_class: String = ""
var _ft_manual_override: bool = false  # True = tester set diff manually, skip auto-eval override
var _ft_input_override: bool = false   # True = pakai slider HR/KR/DR sebagai input fuzzy secara terus-menerus (live)
var _ft_override_btn: CheckButton = null  # referensi toggle override agar bisa diupdate dari tombol preset

# ============================================
# SESSION-BASED SPAWN SYSTEM (ala 20 Minutes Till Dawn)
# ============================================
# Setiap session punya: mob_type, start_time, spawn_cd, max_alive, num_per_spawn, hp_mult, speed_mult
# Session baru aktif seiring waktu → progressive difficulty
const SPAWN_SESSIONS = [
	# === AWAL (0:00) - Pelan, perkenalan ===
	{"mob": "green", "start": 0,   "spawn_cd": 1.5, "max_alive": 15, "num_per_spawn": 2, "hp_mult": 1.0, "speed_mult": 1.0},
	{"mob": "blue",  "start": 0,   "spawn_cd": 2.0, "max_alive": 10, "num_per_spawn": 1, "hp_mult": 1.0, "speed_mult": 1.0},
	
	# === MENIT 1 - Mulai ramp up ===
	{"mob": "green", "start": 60,  "spawn_cd": 1.2, "max_alive": 25, "num_per_spawn": 3, "hp_mult": 1.2, "speed_mult": 1.1},
	
	# === MENIT 1:30 - Red muncul ===
	{"mob": "red",   "start": 90,  "spawn_cd": 3.0, "max_alive": 8,  "num_per_spawn": 1, "hp_mult": 1.0, "speed_mult": 1.0},
	
	# === MENIT 2 - Blue makin agresif ===
	{"mob": "blue",  "start": 120, "spawn_cd": 1.5, "max_alive": 20, "num_per_spawn": 2, "hp_mult": 1.3, "speed_mult": 1.1},
	
	# === MENIT 2:30 - Transisi smooth ke menit 3 (fix difficulty cliff) ===
	{"mob": "green", "start": 150, "spawn_cd": 1.1, "max_alive": 28, "num_per_spawn": 3, "hp_mult": 1.35, "speed_mult": 1.1},
	{"mob": "red",   "start": 150, "spawn_cd": 2.8, "max_alive": 10, "num_per_spawn": 1, "hp_mult": 1.1,  "speed_mult": 1.0},
	
	# === MENIT 3 - Tekanan naik ===
	{"mob": "green", "start": 180, "spawn_cd": 1.0, "max_alive": 35, "num_per_spawn": 4, "hp_mult": 1.5, "speed_mult": 1.2},
	{"mob": "red",   "start": 180, "spawn_cd": 2.5, "max_alive": 15, "num_per_spawn": 2, "hp_mult": 1.3, "speed_mult": 1.1},
	
	# === MENIT 5 - Intense ===
	{"mob": "blue",  "start": 300, "spawn_cd": 1.0, "max_alive": 30, "num_per_spawn": 3, "hp_mult": 1.6, "speed_mult": 1.2},
	{"mob": "red",   "start": 300, "spawn_cd": 2.0, "max_alive": 20, "num_per_spawn": 3, "hp_mult": 1.6, "speed_mult": 1.2},
	
	# === MENIT 7 - Overwhelming ===
	{"mob": "green", "start": 420, "spawn_cd": 0.8, "max_alive": 50, "num_per_spawn": 5, "hp_mult": 2.0, "speed_mult": 1.3},
	{"mob": "red",   "start": 420, "spawn_cd": 1.5, "max_alive": 30, "num_per_spawn": 4, "hp_mult": 2.0, "speed_mult": 1.3},
	
	# === MENIT 10 - Endgame swarm ===
	{"mob": "green", "start": 600, "spawn_cd": 0.5, "max_alive": 60, "num_per_spawn": 6, "hp_mult": 2.5, "speed_mult": 1.5},
	{"mob": "blue",  "start": 600, "spawn_cd": 0.5, "max_alive": 40, "num_per_spawn": 5, "hp_mult": 2.5, "speed_mult": 1.5},
	{"mob": "red",   "start": 600, "spawn_cd": 1.0, "max_alive": 35, "num_per_spawn": 5, "hp_mult": 2.5, "speed_mult": 1.5},
]

# Runtime state per active session
var active_sessions: Array = []  # Array of {session_data, cooldown_timer, alive_count}

# ✨ PRELOAD MOB VARIANTS
const MOB_GREEN = preload("res://mob_green.tscn")
const MOB_BLUE = preload("res://mob_blue.tscn")
const MOB_RED = preload("res://mob_red.tscn")

# HUD references
var timer_label: Label = null
var kills_label: Label = null
var level_label: Label = null
var mode_label: Label = null
var difficulty_label: Label = null

# Normal mode difficulty stages (berdasarkan survival_time)
# Returns [label, color, numeric_value] untuk display
func get_normal_difficulty_info() -> Array:
	if survival_time < 60.0:
		return ["Stage 1", Color(0.3, 1, 0.5), 0.7]        # Green
	elif survival_time < 90.0:
		return ["Stage 2", Color(0.5, 0.9, 1.0), 0.85]     # Cyan
	elif survival_time < 120.0:
		return ["Stage 3", Color(1, 0.85, 0.3), 1.0]       # Yellow
	elif survival_time < 180.0:
		return ["Stage 4", Color(1, 0.7, 0.3), 1.1]        # Orange-yellow
	elif survival_time < 300.0:
		return ["Stage 5", Color(1, 0.55, 0.2), 1.2]       # Orange
	elif survival_time < 420.0:
		return ["Stage 6", Color(1, 0.4, 0.2), 1.35]       # Orange-red
	elif survival_time < 600.0:
		return ["Stage 7", Color(1, 0.3, 0.3), 1.5]        # Red
	else:
		return ["MAX", Color(1, 0.2, 0.8), 2.0]            # Magenta = endgame

func _ready():
	add_to_group("game")
	_initialize_nodes()
	_create_hud()
	_connect_signals()
	game_started = true
	_initialize_sessions()
	_initialize_fuzzy()
	if GameManager.is_debug():
		_create_debug_overlay()
		_create_fuzzy_tester()
	# Tutorial untuk first timer (skip di Debug mode)
	if not GameManager.is_debug() and not GameManager.has_seen_tutorial:
		_spawn_tutorial()
	BGM.play_track("res://Audio/Juhani Junkala [Retro Game Music Pack] Level 1.wav", -10.0)

func _spawn_tutorial() -> void:
	var TutorialOverlay = load("res://tutorial_overlay.gd")
	if not TutorialOverlay:
		push_warning("⚠️ tutorial_overlay.gd tidak ditemukan!")
		return
	var tutorial = TutorialOverlay.new()
	add_child(tutorial)
	# Tunggu satu frame agar node siap, lalu setup
	await get_tree().process_frame
	if is_instance_valid(tutorial):
		tutorial.setup(player, upgrade_menu)
	print("📖 Tutorial dimulai")

func _process(delta):
	if game_started and not get_tree().paused:
		survival_time += delta
		_update_hud()
		_activate_new_sessions()
		_process_spawning(delta)
		_process_fuzzy(delta)
		if GameManager.is_debug():
			_update_debug_overlay()

func _input(event):
	# Toggle pause dengan ESC
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			_pause_game()
	# F1: Toggle Fuzzy Tester (debug only)
	if GameManager.is_debug() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_fuzzy_tester()
			get_viewport().set_input_as_handled()

# ============================================
# FUZZY DDA INITIALIZATION & PROCESSING
# ============================================
func _initialize_fuzzy():
	if GameManager.is_fuzzy():
		var FuzzyDDA = load("res://fuzzy_dda.gd")
		fuzzy_dda = FuzzyDDA.new()
		fuzzy_difficulty = 1.0
		fuzzy_eval_timer = 0.0
		kills_window = []
		damage_window = []
		fuzzy_difficulty_sum = 0.0
		fuzzy_difficulty_count = 0
		print("🧠 Fuzzy DDA System initialized!")
	
	# Connect damage signal for tracking
	if player and player.has_signal("damage_received"):
		if not player.damage_received.is_connected(_on_player_damage_received):
			player.damage_received.connect(_on_player_damage_received)
			print("  ✅ damage_received connected for fuzzy tracking")

func _process_fuzzy(delta: float):
	if not GameManager.is_fuzzy() or fuzzy_dda == null:
		return
	
	# Cleanup old data from windows
	_cleanup_performance_windows()
	
	# Evaluate fuzzy logic setiap FUZZY_EVAL_INTERVAL detik
	fuzzy_eval_timer += delta
	if fuzzy_eval_timer >= FUZZY_EVAL_INTERVAL:
		fuzzy_eval_timer = 0.0
		_evaluate_fuzzy()

func _evaluate_fuzzy():
	if not player or not is_instance_valid(player) or fuzzy_dda == null:
		return
	
	# Calculate inputs (debug: bisa di-override dari slider tester)
	var health_ratio: float
	var kill_rate: float
	var damage_total: float = 0.0
	if GameManager.is_debug() and _ft_input_override and _ft_sliders.has("health"):
		health_ratio = _ft_sliders["health"].value
		kill_rate    = _ft_sliders["kills"].value
		damage_total = _ft_sliders["damage"].value
	else:
		health_ratio = player.health / player.max_health
		kill_rate = float(kills_window.size())  # kills in last 30s
		for entry in damage_window:
			damage_total += entry[1]
	
	# Evaluate fuzzy logic
	var old_difficulty = fuzzy_difficulty
	var result = fuzzy_dda.evaluate(health_ratio, kill_rate, damage_total)
	
	# Warm-up lock: 30 detik pertama max NORMAL (1.0) untuk onboarding
	# Skip di debug mode agar langsung responsif
	if survival_time < 30.0 and not GameManager.is_debug():
		result = minf(result, 1.0)
	
	# Jika tester sudah manual override (sekali pakai) DAN input override tidak aktif, jangan timpa
	if _ft_manual_override and not _ft_input_override:
		_ft_manual_override = false
		return
	
	fuzzy_difficulty = result
	
	# Debug input override: terapkan langsung ke musuh yang sudah ada (live)
	if GameManager.is_debug() and _ft_input_override:
		for m in get_tree().get_nodes_in_group("mobs"):
			if m.has_method("update_fuzzy_difficulty"):
				m.update_fuzzy_difficulty(result)
	
	# Track for average
	fuzzy_difficulty_sum += fuzzy_difficulty
	fuzzy_difficulty_count += 1
	_dbg_eval_count += 1
	
	# Simpan nilai untuk debug overlay
	if GameManager.is_debug():
		_dbg_health_ratio = health_ratio
		_dbg_kill_rate    = kill_rate
		_dbg_damage_rate  = damage_total
		# Hitung derajat keanggotaan
		_dbg_h_low  = fuzzy_dda._health_low(health_ratio)
		_dbg_h_med  = fuzzy_dda._health_medium(health_ratio)
		_dbg_h_high = fuzzy_dda._health_high(health_ratio)
		_dbg_k_low  = fuzzy_dda._kill_low(kill_rate)
		_dbg_k_med  = fuzzy_dda._kill_medium(kill_rate)
		_dbg_k_high = fuzzy_dda._kill_high(kill_rate)
		_dbg_d_low  = fuzzy_dda._damage_low(damage_total)
		_dbg_d_med  = fuzzy_dda._damage_medium(damage_total)
		_dbg_d_high = fuzzy_dda._damage_high(damage_total)
		# Label output
		if fuzzy_difficulty <= 0.70:
			_dbg_last_output = "VERY EASY"
		elif fuzzy_difficulty <= 0.90:
			_dbg_last_output = "EASY"
		elif fuzzy_difficulty <= 1.10:
			_dbg_last_output = "NORMAL"
		elif fuzzy_difficulty <= 1.35:
			_dbg_last_output = "HARD"
		else:
			_dbg_last_output = "VERY HARD"
	
	# Log
	var diff_change = ""
	if fuzzy_difficulty > old_difficulty + 0.05:
		diff_change = "📈 UP"
	elif fuzzy_difficulty < old_difficulty - 0.05:
		diff_change = "📉 DOWN"
	else:
		diff_change = "➡️ STABLE"
	
	print("🧠 Fuzzy DDA Eval: HP=%.0f%%, Kills/30s=%d, Dmg/30s=%.0f → Difficulty=%.2f (%s)" % [
		health_ratio * 100, kills_window.size(), damage_total, fuzzy_difficulty, diff_change
	])

func _cleanup_performance_windows():
	var cutoff = survival_time - PERFORMANCE_WINDOW
	
	# Clean kills window
	while kills_window.size() > 0 and kills_window[0] < cutoff:
		kills_window.pop_front()
	
	# Clean damage window
	while damage_window.size() > 0 and damage_window[0][0] < cutoff:
		damage_window.pop_front()

func _on_player_damage_received(amount: float):
	if GameManager.is_fuzzy():
		damage_window.append([survival_time, amount])

func get_fuzzy_average_difficulty() -> float:
	if fuzzy_difficulty_count <= 0:
		return 1.0
	return fuzzy_difficulty_sum / fuzzy_difficulty_count

# ============================================
# HUD SYSTEM
# ============================================
func _create_hud():
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	add_child(hud)
	
	# Load pixel font
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")
	
	# --- TOP BAR BACKGROUND ---
	var top_bg = ColorRect.new()
	top_bg.name = "TopBG"
	top_bg.color = Color(0.04, 0.06, 0.12, 0.78)
	top_bg.anchor_left = 0.0
	top_bg.anchor_right = 1.0
	top_bg.anchor_top = 0.0
	top_bg.anchor_bottom = 0.0
	top_bg.offset_top = 0
	top_bg.offset_bottom = 52
	hud.add_child(top_bg)
	
	# Container di atas layar
	var top_container = HBoxContainer.new()
	top_container.name = "TopContainer"
	top_container.anchor_left = 0.0
	top_container.anchor_right = 1.0
	top_container.anchor_top = 0.0
	top_container.offset_top = 8
	top_container.offset_bottom = 50
	top_container.offset_left = 20
	top_container.offset_right = -20
	top_container.alignment = BoxContainer.ALIGNMENT_CENTER
	top_container.add_theme_constant_override("separation", 30)
	hud.add_child(top_container)
	
	# Mode Label (paling kiri)
	mode_label = Label.new()
	mode_label.name = "ModeLabel"
	mode_label.text = GameManager.get_mode_name()
	mode_label.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		mode_label.add_theme_font_override("font", pixel_font)
	if GameManager.is_fuzzy():
		mode_label.add_theme_color_override("font_color", Color(0.72, 0.55, 1.0))  # Purple for Fuzzy
	else:
		mode_label.add_theme_color_override("font_color", Color(0.4, 0.92, 0.52))  # Green for Normal
	mode_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	mode_label.add_theme_constant_override("outline_size", 3)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.add_child(mode_label)
	
	# Timer Label (center, besar)
	timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "0:00"
	timer_label.add_theme_font_size_override("font_size", 24)
	if pixel_font:
		timer_label.add_theme_font_override("font", pixel_font)
	timer_label.add_theme_color_override("font_color", Color(1, 0.9, 0.25))
	timer_label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0, 1))
	timer_label.add_theme_constant_override("outline_size", 3)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.add_child(timer_label)
	
	# Kills Label
	kills_label = Label.new()
	kills_label.name = "KillsLabel"
	kills_label.text = "Kill: 0"
	kills_label.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		kills_label.add_theme_font_override("font", pixel_font)
	kills_label.add_theme_color_override("font_color", Color(1, 0.42, 0.42))
	kills_label.add_theme_color_override("font_outline_color", Color(0.3, 0, 0, 1))
	kills_label.add_theme_constant_override("outline_size", 3)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kills_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.add_child(kills_label)
	
	# Level Label
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv.1"
	level_label.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		level_label.add_theme_font_override("font", pixel_font)
	level_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	level_label.add_theme_color_override("font_outline_color", Color(0, 0.2, 0.3, 1))
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.add_child(level_label)
	
	# Difficulty Label (untuk semua mode)
	difficulty_label = Label.new()
	difficulty_label.name = "DifficultyLabel"
	if GameManager.is_fuzzy():
		difficulty_label.text = "1.00"
	else:
		difficulty_label.text = "Stage 1"
	difficulty_label.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		difficulty_label.add_theme_font_override("font", pixel_font)
	difficulty_label.add_theme_color_override("font_color", Color(0.25, 1, 0.5))  # Mulai hijau
	difficulty_label.add_theme_color_override("font_outline_color", Color(0, 0.2, 0.1, 1))
	difficulty_label.add_theme_constant_override("outline_size", 3)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	difficulty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_container.add_child(difficulty_label)
	
	# Mobile Pause Button
	var show_joystick = false
	if OS.has_feature("web"):
		var js_result = JavaScriptBridge.eval("/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);")
		if js_result:
			show_joystick = true
	else:
		if DisplayServer.is_touchscreen_available():
			show_joystick = true
			
	if show_joystick:
		var pause_btn = Button.new()
		pause_btn.name = "MobilePauseBtn"
		pause_btn.text = "II"
		if pixel_font:
			pause_btn.add_theme_font_override("font", pixel_font)
		pause_btn.add_theme_font_size_override("font_size", 24)
		pause_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		pause_btn.add_theme_color_override("font_hover_color", Color(0.8, 1.0, 0.8))
		pause_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		pause_btn.add_theme_constant_override("outline_size", 3)
		# Stylebox agar tidak ada background tebal, transparan
		var flat = StyleBoxFlat.new()
		flat.bg_color = Color(0, 0, 0, 0.5)
		flat.corner_radius_top_left = 10
		flat.corner_radius_top_right = 10
		flat.corner_radius_bottom_left = 10
		flat.corner_radius_bottom_right = 10
		flat.content_margin_left = 12
		flat.content_margin_right = 12
		pause_btn.add_theme_stylebox_override("normal", flat)
		pause_btn.add_theme_stylebox_override("hover", flat)
		pause_btn.add_theme_stylebox_override("pressed", flat)
		pause_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		# Posisikan tombol di bawah top bar, di pojok kanan
		pause_btn.anchors_preset = Control.PRESET_TOP_RIGHT
		pause_btn.anchor_left = 1.0
		pause_btn.anchor_right = 1.0
		pause_btn.anchor_top = 0.0
		pause_btn.anchor_bottom = 0.0
		pause_btn.offset_left = -120
		pause_btn.offset_top = 80
		pause_btn.offset_right = -40
		pause_btn.offset_bottom = 160
		
		# Tambahkan langsung ke hud, BUKAN ke top_container
		hud.add_child(pause_btn)
		
		# Connect signal ke _pause_game() via defer atau callable
		pause_btn.pressed.connect(func():
			if not get_tree().paused:
				_pause_game()
		)

func _update_hud():
	if not timer_label:
		return
	
	# Timer count UP (endless)
	var minutes = int(survival_time) / 60
	var seconds = int(survival_time) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	
	
	# Kills
	kills_label.text = "Kill: %d" % total_kills
	
	# Level
	if player and is_instance_valid(player):
		level_label.text = "Lv.%d" % player.level
	
	# Difficulty Label — Fuzzy mode: numeric, Normal mode: stage
	if difficulty_label:
		if GameManager.is_fuzzy():
			difficulty_label.text = "%.2f" % fuzzy_difficulty
			# Warna berubah sesuai level difficulty
			if fuzzy_difficulty >= 1.3:
				difficulty_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))   # Red
			elif fuzzy_difficulty >= 1.1:
				difficulty_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))   # Orange
			elif fuzzy_difficulty <= 0.7:
				difficulty_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))   # Green
			elif fuzzy_difficulty <= 0.9:
				difficulty_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1))   # Blue
			else:
				difficulty_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3)) # Yellow
		else:
			# Normal mode: tampilkan stage berdasarkan waktu
			var info = get_normal_difficulty_info()
			difficulty_label.text = info[0]
			difficulty_label.add_theme_color_override("font_color", info[1])

# ============================================
# DEBUG OVERLAY
# ============================================
func _create_debug_overlay():
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")
	
	# CanvasLayer di atas HUD
	var cl = CanvasLayer.new()
	cl.name = "DebugLayer"
	cl.layer = 20
	add_child(cl)
	
	# Panel latar
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	
	# Styling panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.10, 0.65)   # semi-transparan
	style.border_color = Color(0.4, 0.25, 0.85, 0.6)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 10
	style.content_margin_right  = 10
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	debug_panel.add_theme_stylebox_override("panel", style)
	
	# Anchor: pojok KIRI ATAS
	debug_panel.anchor_left   = 0.0
	debug_panel.anchor_right  = 0.0
	debug_panel.anchor_top    = 0.0
	debug_panel.anchor_bottom = 0.0
	debug_panel.offset_left   = 8
	debug_panel.offset_right  = 308    # lebar tetap
	debug_panel.offset_top    = 58     # di bawah bar HUD
	debug_panel.offset_bottom = 490
	cl.add_child(debug_panel)
	
	# VBox isi
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_panel.add_child(vbox)
	
	# Helper buat row (HBoxContainer dengan judul di kiri, nilai di kanan)
	var make_row = func(key: String, title: String, init_val: String, color: Color = Color.WHITE) -> Label:
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		var title_lbl = Label.new()
		title_lbl.text = title
		title_lbl.add_theme_font_size_override("font_size", 7)
		if pixel_font:
			title_lbl.add_theme_font_override("font", pixel_font)
		title_lbl.add_theme_color_override("font_color", color)
		title_lbl.add_theme_color_override("font_outline_color", Color(0,0,0,1))
		title_lbl.add_theme_constant_override("outline_size", 2)
		hbox.add_child(title_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = init_val
		val_lbl.add_theme_font_size_override("font_size", 7)
		if pixel_font:
			val_lbl.add_theme_font_override("font", pixel_font)
		val_lbl.add_theme_color_override("font_color", color)
		val_lbl.add_theme_color_override("font_outline_color", Color(0,0,0,1))
		val_lbl.add_theme_constant_override("outline_size", 2)
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(val_lbl)
		
		debug_labels[key] = val_lbl
		return val_lbl
	
	var sep = func(label: String):
		var lbl = Label.new()
		lbl.text = label
		lbl.add_theme_font_size_override("font_size", 6)
		if pixel_font: lbl.add_theme_font_override("font", pixel_font)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
		vbox.add_child(lbl)
	
	# Header
	sep.call("── DEBUG FUZZY DDA ──")
	make_row.call("eval_count", "Eval",        "#0",      Color(0.8, 0.8, 0.8))
	make_row.call("next_eval",  "Next eval",   "8.0s",    Color(0.8, 0.8, 0.8))
	make_row.call("avg_diff",   "Avg mult",    "1.000",   Color(0.8, 0.8, 0.8))
	
	sep.call("── INPUTS ──────────")
	make_row.call("hp_ratio",   "HP Ratio",    "1.000",   Color(0.4, 1.0, 0.5))
	make_row.call("kill_rate",  "Kill/30s",    "0",       Color(1.0, 0.6, 0.3))
	make_row.call("dmg_rate",   "Dmg/30s",     "0.0",     Color(1.0, 0.3, 0.4))
	
	sep.call("── MEMBERSHIP ──────")
	make_row.call("h_low",  "Health Low",     "0.000",  Color(0.4, 1.0, 0.5))
	make_row.call("h_med",  "Health Med",     "0.000",  Color(0.4, 1.0, 0.5))
	make_row.call("h_high", "Health High",    "0.000",  Color(0.4, 1.0, 0.5))
	make_row.call("k_low",  "Kills Low",      "0.000",  Color(1.0, 0.6, 0.3))
	make_row.call("k_med",  "Kills Med",      "0.000",  Color(1.0, 0.6, 0.3))
	make_row.call("k_high", "Kills High",     "0.000",  Color(1.0, 0.6, 0.3))
	make_row.call("d_low",  "Damage Low",     "0.000",  Color(1.0, 0.3, 0.4))
	make_row.call("d_med",  "Damage Med",     "0.000",  Color(1.0, 0.3, 0.4))
	make_row.call("d_high", "Damage High",    "0.000",  Color(1.0, 0.3, 0.4))
	
	sep.call("── OUTPUT ──────────")
	make_row.call("output_label", "Class",     "NORMAL",  Color(1.0, 0.85, 0.3))
	make_row.call("multiplier",   "Mult",      "1.000",   Color(1.0, 0.85, 0.3))
	make_row.call("kills_window", "Win.Kills", "0",       Color(0.7, 0.7, 0.7))
	
	sep.call("── SPAWNER ─────────")
	make_row.call("total_mobs", "Total mobs", "0",       Color(0.9, 0.9, 0.9))
	make_row.call("spawn_cd",   "Cooldown",   "x1.00",   Color(0.5, 0.9, 1.0))
	make_row.call("spawn_max",  "Limit",      "x1.00",   Color(0.5, 0.9, 1.0))
	make_row.call("spawn_num",  "Spawn qty",  "x1.00",   Color(0.5, 0.9, 1.0))
	
	print("🐛 Debug overlay created")

func _update_debug_overlay():
	if not debug_panel or debug_labels.is_empty():
		return
	
	# --- Timer ---
	var time_left = FUZZY_EVAL_INTERVAL - fuzzy_eval_timer
	_set_lbl("eval_count", "#%d" % _dbg_eval_count)
	_set_lbl("next_eval",  "%.1fs" % time_left)
	var avg = get_fuzzy_average_difficulty()
	_set_lbl("avg_diff",   "%.3f" % avg)
	
	# --- Inputs ---
	_set_lbl("hp_ratio",  "%d%% (%.3f)" % [int(_dbg_health_ratio * 100), _dbg_health_ratio])
	_set_lbl("kill_rate", "%d"   % int(_dbg_kill_rate))
	_set_lbl("dmg_rate",  "%.1f" % _dbg_damage_rate)
	
	# --- Membership ---
	_set_lbl("h_low",  "%.3f" % _dbg_h_low)
	_set_lbl("h_med",  "%.3f" % _dbg_h_med)
	_set_lbl("h_high", "%.3f" % _dbg_h_high)
	_set_lbl("k_low",  "%.3f" % _dbg_k_low)
	_set_lbl("k_med",  "%.3f" % _dbg_k_med)
	_set_lbl("k_high", "%.3f" % _dbg_k_high)
	_set_lbl("d_low",  "%.3f" % _dbg_d_low)
	_set_lbl("d_med",  "%.3f" % _dbg_d_med)
	_set_lbl("d_high", "%.3f" % _dbg_d_high)
	
	# --- Output ---
	_set_lbl("output_label", _dbg_last_output if not _dbg_last_output.is_empty() else "--")
	_set_lbl("multiplier",   "%.3f" % fuzzy_difficulty)
	_set_lbl("kills_window", "%d" % kills_window.size())
	
	# --- Spawner ---
	_set_lbl("total_mobs", "%d/%d" % [total_mob_count, MAX_TOTAL_MOBS])
	_set_lbl("spawn_cd",   "x%.2f" % (1.0 / max(0.01, fuzzy_difficulty)))
	_set_lbl("spawn_max",  "x%.2f" % fuzzy_difficulty)
	_set_lbl("spawn_num",  "x%.2f" % fuzzy_difficulty)
	
	# Warna multiplier sesuai level
	var mult_lbl = debug_labels.get("multiplier")
	if mult_lbl:
		if fuzzy_difficulty >= 1.35:
			mult_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif fuzzy_difficulty >= 1.1:
			mult_lbl.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
		elif fuzzy_difficulty <= 0.7:
			mult_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
		elif fuzzy_difficulty <= 0.9:
			mult_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1))
		else:
			mult_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))

func _set_lbl(key: String, text: String):
	var lbl = debug_labels.get(key)
	if lbl:
		lbl.text = text

# ============================================
# FUZZY TESTER PANEL
# ============================================
func _create_fuzzy_tester():
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")
	
	# Gunakan DebugLayer yang sudah ada
	var cl = get_node_or_null("DebugLayer")
	if not cl:
		cl = CanvasLayer.new()
		cl.name = "DebugLayer"
		cl.layer = 20
		add_child(cl)
	
	fuzzy_tester_panel = PanelContainer.new()
	fuzzy_tester_panel.name = "FuzzyTesterPanel"
	fuzzy_tester_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color            = Color(0.02, 0.06, 0.12, 0.92)
	style.border_color        = Color(0.25, 0.85, 0.45, 0.75)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 10
	style.content_margin_right  = 10
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	fuzzy_tester_panel.add_theme_stylebox_override("panel", style)
	
	# Posisi: kanan layar
	fuzzy_tester_panel.anchor_left   = 1.0
	fuzzy_tester_panel.anchor_right  = 1.0
	fuzzy_tester_panel.anchor_top    = 0.0
	fuzzy_tester_panel.anchor_bottom = 0.0
	fuzzy_tester_panel.offset_left   = -338
	fuzzy_tester_panel.offset_right  = -8
	fuzzy_tester_panel.offset_top    = 58
	fuzzy_tester_panel.offset_bottom = 720
	cl.add_child(fuzzy_tester_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuzzy_tester_panel.add_child(vbox)
	
	# Helper: section separator
	var mk_sep = func(text: String):
		var l = Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", 6)
		if pixel_font: l.add_theme_font_override("font", pixel_font)
		l.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		vbox.add_child(l)
	
	# Helper: slider row
	var mk_slider = func(key: String, lbl_text: String, mn: float, mx: float, init: float, step: float):
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		vbox.add_child(hbox)
		var tl = Label.new()
		tl.text = lbl_text
		tl.add_theme_font_size_override("font_size", 6)
		if pixel_font: tl.add_theme_font_override("font", pixel_font)
		tl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		tl.custom_minimum_size.x = 72
		hbox.add_child(tl)
		var sl = HSlider.new()
		sl.min_value = mn
		sl.max_value = mx
		sl.value = init
		sl.step = step
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(sl)
		var vl = Label.new()
		vl.text = "%.2f" % init
		vl.add_theme_font_size_override("font_size", 6)
		if pixel_font: vl.add_theme_font_override("font", pixel_font)
		vl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		vl.custom_minimum_size.x = 36
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(vl)
		_ft_sliders[key] = sl
		_ft_val_labels[key] = vl
		sl.value_changed.connect(func(v):
			vl.text = "%.2f" % v
			if _ft_input_override:
				_fuzzy_tester_evaluate()
		)
	
	# Helper: result row
	var mk_res = func(key: String, lbl_text: String, init: String, col: Color = Color.WHITE):
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		var tl = Label.new()
		tl.text = lbl_text
		tl.add_theme_font_size_override("font_size", 6)
		if pixel_font: tl.add_theme_font_override("font", pixel_font)
		tl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		tl.custom_minimum_size.x = 90
		hbox.add_child(tl)
		var vl = Label.new()
		vl.text = init
		vl.add_theme_font_size_override("font_size", 6)
		if pixel_font: vl.add_theme_font_override("font", pixel_font)
		vl.add_theme_color_override("font_color", col)
		vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(vl)
		_ft_result_labels[key] = vl
	
	# ── HEADER
	mk_sep.call("─ FUZZY TESTER [F1 TOGGLE] ─")
	
	# ── INPUTS
	mk_sep.call("── INPUTS ──────────────")
	mk_slider.call("health", "HP Ratio",  0.0, 1.0,   1.0, 0.01)
	mk_slider.call("kills",  "Kill/30s",  0.0, 20.0,  0.0, 1.0)
	mk_slider.call("damage", "Dmg/30s",   0.0, 100.0, 0.0, 1.0)
	
	# ── EVALUATE BUTTON
	var eval_btn = Button.new()
	eval_btn.text = "EVALUATE"
	eval_btn.add_theme_font_size_override("font_size", 8)
	if pixel_font: eval_btn.add_theme_font_override("font", pixel_font)
	vbox.add_child(eval_btn)
	eval_btn.pressed.connect(_fuzzy_tester_evaluate)
	
	# ── OVERRIDE INPUT (live): pakai slider sebagai input fuzzy terus-menerus
	var ovr_btn = CheckButton.new()
	ovr_btn.text = "OVERRIDE INPUT (live)"
	ovr_btn.add_theme_font_size_override("font_size", 7)
	if pixel_font: ovr_btn.add_theme_font_override("font", pixel_font)
	vbox.add_child(ovr_btn)
	_ft_override_btn = ovr_btn
	ovr_btn.toggled.connect(func(on):
		_ft_input_override = on
		if on:
			_fuzzy_tester_evaluate()
	)
	
	# ── RESULT
	mk_sep.call("── RESULT ──────────────")
	mk_res.call("res_mult",  "Multiplier", "--", Color(1.0, 0.85, 0.3))
	mk_res.call("res_class", "Class",      "--", Color(1.0, 0.85, 0.3))
	mk_sep.call("── MEMBERSHIP ──────────")
	mk_res.call("res_h", "Health μ", "--", Color(0.4,  1.0,  0.5))
	mk_res.call("res_k", "Kills μ",  "--", Color(1.0,  0.6,  0.3))
	mk_res.call("res_d", "Damage μ", "--", Color(1.0,  0.3,  0.4))
	
	# ── PRESET INPUT
	mk_sep.call("── PRESET INPUT ────────")
	var preset_lbl = Label.new()
	preset_lbl.text = "Pilih preset:"
	preset_lbl.add_theme_font_size_override("font_size", 6)
	if pixel_font: preset_lbl.add_theme_font_override("font", pixel_font)
	preset_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	vbox.add_child(preset_lbl)
	
	# Preset values: {hp, kills, damage} yang representatif tiap class
	# Nilai dipilih agar fuzzy output jatuh di kelas tersebut
	const DIFF_LABELS  = ["VE",  "E",   "N",   "H",   "VH" ]
	const DIFF_COLORS  = [
		Color(0.3,  0.9,  1.0),   # VE - cyan
		Color(0.3,  1.0,  0.5),   # E  - green
		Color(1.0,  0.85, 0.3),   # N  - yellow
		Color(1.0,  0.55, 0.2),   # H  - orange
		Color(1.0,  0.25, 0.25),  # VH - red
	]
	# hp_ratio, kill_rate, damage_rate
	const DIFF_PRESETS = [
		{"hp": 0.10, "kills": 1.0,  "damage": 80.0},  # VE: sekarat, kill dikit, damage gede
		{"hp": 0.30, "kills": 1.0,  "damage": 8.0 },  # E:  HP rendah, aman
		{"hp": 0.50, "kills": 7.0,  "damage": 40.0},  # N:  semua medium
		{"hp": 0.85, "kills": 6.0,  "damage": 5.0 },  # H:  HP tinggi, damage dikit
		{"hp": 0.90, "kills": 16.0, "damage": 0.0 },  # VH: HP penuh, kill banyak, aman
	]
	
	var diff_hbox = HBoxContainer.new()
	diff_hbox.add_theme_constant_override("separation", 3)
	vbox.add_child(diff_hbox)
	
	_ft_diff_buttons.clear()
	for di in range(5):
		var dbtn = Button.new()
		dbtn.text = DIFF_LABELS[di]
		dbtn.add_theme_font_size_override("font_size", 7)
		if pixel_font: dbtn.add_theme_font_override("font", pixel_font)
		dbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dbtn.toggle_mode = false
		diff_hbox.add_child(dbtn)
		_ft_diff_buttons.append(dbtn)
		# Semua dim di awal
		dbtn.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		# Capture
		var c_idx     = di
		var c_colors  = DIFF_COLORS
		var c_presets = DIFF_PRESETS
		dbtn.pressed.connect(func():
			# Highlight tombol yang dipilih
			for bi in range(_ft_diff_buttons.size()):
				_ft_diff_buttons[bi].add_theme_color_override("font_color",
					c_colors[bi] if bi == c_idx else Color(0.35, 0.35, 0.35))
			# Update expected index agar match label compare ke class yang benar
			_ft_expected_idx = c_idx
			# Set slider ke preset
			var p = c_presets[c_idx]
			_ft_sliders["health"].value = p["hp"]
			_ft_sliders["kills"].value  = p["kills"]
			_ft_sliders["damage"].value = p["damage"]
			# Update value labels slider
			_ft_val_labels["health"].text = "%.2f" % p["hp"]
			_ft_val_labels["kills"].text  = "%.2f" % p["kills"]
			_ft_val_labels["damage"].text = "%.2f" % p["damage"]
			# Aktifkan override input agar skenario target ini bertahan (tidak ditimpa gameplay tiap 4 detik)
			_ft_input_override = true
			if _ft_override_btn: _ft_override_btn.set_pressed_no_signal(true)
			# Auto-evaluate
			_fuzzy_tester_evaluate()
		)
	
	_ft_match_label = Label.new()
	_ft_match_label.text = ""
	_ft_match_label.add_theme_font_size_override("font_size", 7)
	if pixel_font: _ft_match_label.add_theme_font_override("font", pixel_font)
	_ft_match_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	_ft_match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_ft_match_label)
	
	# ── LOG BUTTON
	var log_btn = Button.new()
	log_btn.text = "CATAT HASIL"
	log_btn.add_theme_font_size_override("font_size", 7)
	if pixel_font: log_btn.add_theme_font_override("font", pixel_font)
	vbox.add_child(log_btn)
	log_btn.pressed.connect(_fuzzy_tester_log_test)
	
	var clear_btn = Button.new()
	clear_btn.text = "HAPUS LOG"
	clear_btn.add_theme_font_size_override("font_size", 6)
	if pixel_font: clear_btn.add_theme_font_override("font", pixel_font)
	vbox.add_child(clear_btn)
	clear_btn.pressed.connect(func(): _ft_test_log.clear(); _fuzzy_tester_refresh_log())
	
	# ── HISTORY LOG
	mk_sep.call("── LOG TEST CASES ──────")
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 110
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_ft_log_vbox = VBoxContainer.new()
	_ft_log_vbox.add_theme_constant_override("separation", 2)
	_ft_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_ft_log_vbox)
	_fuzzy_tester_refresh_log()
	print("🧪 Fuzzy Tester Panel created (F1 to toggle)")

func _toggle_fuzzy_tester():
	if not fuzzy_tester_panel:
		return
	fuzzy_tester_visible = !fuzzy_tester_visible
	fuzzy_tester_panel.visible = fuzzy_tester_visible

func _fuzzy_tester_evaluate():
	if fuzzy_dda == null:
		var FuzzyDDA = load("res://fuzzy_dda.gd")
		fuzzy_dda = FuzzyDDA.new()
	
	var health = _ft_sliders["health"].value
	var kills  = _ft_sliders["kills"].value
	var damage = _ft_sliders["damage"].value
	
	var result = fuzzy_dda.evaluate(health, kills, damage)
	_ft_last_result = result
	
	# Apply ke game langsung — spawner pakai fuzzy_difficulty ini
	fuzzy_difficulty = result
	_ft_manual_override = true  # Tandai manual override; auto-eval skip sekali
	
	# Update existing mobs in real time (debug mode)
	var mobs = get_tree().get_nodes_in_group("mobs")
	for m in mobs:
		if m.has_method("update_fuzzy_difficulty"):
			m.update_fuzzy_difficulty(result)
			
	# Tentukan class
	var cls: String
	if result <= 0.70:
		cls = "VERY EASY"
	elif result <= 0.90:
		cls = "EASY"
	elif result <= 1.10:
		cls = "NORMAL"
	elif result <= 1.35:
		cls = "HARD"
	else:
		cls = "VERY HARD"
	_ft_last_class = cls
	
	var col = Color(1, 0.85, 0.3)
	if result >= 1.35:   col = Color(1, 0.3, 0.3)
	elif result >= 1.1:  col = Color(1, 0.7, 0.3)
	elif result <= 0.7:  col = Color(0.3, 1, 0.5)
	elif result <= 0.9:  col = Color(0.5, 0.9, 1)
	
	if "res_mult" in _ft_result_labels:
		_ft_result_labels["res_mult"].text = "%.4f" % result
		_ft_result_labels["res_mult"].add_theme_color_override("font_color", col)
	if "res_class" in _ft_result_labels:
		_ft_result_labels["res_class"].text = cls
		_ft_result_labels["res_class"].add_theme_color_override("font_color", col)
	
	# Membership
	var h_low  = fuzzy_dda._health_low(health)
	var h_med  = fuzzy_dda._health_medium(health)
	var h_high = fuzzy_dda._health_high(health)
	var k_low  = fuzzy_dda._kill_low(kills)
	var k_med  = fuzzy_dda._kill_medium(kills)
	var k_high = fuzzy_dda._kill_high(kills)
	var d_low  = fuzzy_dda._damage_low(damage)
	var d_med  = fuzzy_dda._damage_medium(damage)
	var d_high = fuzzy_dda._damage_high(damage)
	
	if "res_h" in _ft_result_labels:
		_ft_result_labels["res_h"].text = "L:%.2f M:%.2f H:%.2f" % [h_low, h_med, h_high]
	if "res_k" in _ft_result_labels:
		_ft_result_labels["res_k"].text = "L:%.2f M:%.2f H:%.2f" % [k_low, k_med, k_high]
	if "res_d" in _ft_result_labels:
		_ft_result_labels["res_d"].text = "L:%.2f M:%.2f H:%.2f" % [d_low, d_med, d_high]
	
	_fuzzy_tester_check_match()
	print("🧪 Test: HP=%.2f K=%.0f D=%.0f → %.4f (%s)" % [health, kills, damage, result, cls])

func _fuzzy_tester_check_match():
	if _ft_last_class.is_empty() or not _ft_match_label:
		return
	var names = ["VERY EASY", "EASY", "NORMAL", "HARD", "VERY HARD"]
	var expected = names[_ft_expected_idx]
	if _ft_last_class == expected:
		_ft_match_label.text = "✅  CORRECT  (%s)" % _ft_last_class
		_ft_match_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
	else:
		_ft_match_label.text = "❌  SALAH  got:%s  exp:%s" % [_ft_last_class, expected]
		_ft_match_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _fuzzy_tester_log_test():
	if _ft_last_result < 0.0:
		if _ft_match_label:
			_ft_match_label.text = "⚠  Evaluate dulu!"
		return
	var names = ["VERY EASY", "EASY", "NORMAL", "HARD", "VERY HARD"]
	var expected = names[_ft_expected_idx]
	_ft_test_log.append({
		"n":      _ft_test_log.size() + 1,
		"hp":     _ft_sliders["health"].value,
		"kills":  _ft_sliders["kills"].value,
		"damage": _ft_sliders["damage"].value,
		"mult":   _ft_last_result,
		"actual": _ft_last_class,
		"expect": expected,
		"ok":     (_ft_last_class == expected),
	})
	_fuzzy_tester_refresh_log()

func _fuzzy_tester_refresh_log():
	if not _ft_log_vbox:
		return
	for child in _ft_log_vbox.get_children():
		child.queue_free()
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")
	if _ft_test_log.is_empty():
		var el = Label.new()
		el.text = "(kosong)"
		el.add_theme_font_size_override("font_size", 5)
		if pixel_font: el.add_theme_font_override("font", pixel_font)
		el.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_ft_log_vbox.add_child(el)
		return
	# Tampilkan newest-first, max 10
	var entries = _ft_test_log.duplicate()
	entries.reverse()
	for i in range(mini(entries.size(), 10)):
		var e = entries[i]
		var abbr = func(s: String) -> String:
			match s:
				"VERY EASY": return "VE"
				"EASY":      return "E"
				"NORMAL":    return "N"
				"HARD":      return "H"
				"VERY HARD": return "VH"
				_:           return "?"
		var icon = "✅" if e["ok"] else "❌"
		var lbl = Label.new()
		lbl.text = "#%d %s HP:%.2f K:%.0f D:%.0f →%s(e:%s)" % [
			e["n"], icon, e["hp"], e["kills"], e["damage"],
			abbr.call(e["actual"]), abbr.call(e["expect"])
		]
		lbl.add_theme_font_size_override("font_size", 5)
		if pixel_font: lbl.add_theme_font_override("font", pixel_font)
		lbl.add_theme_color_override("font_color", Color(0.4, 1, 0.5) if e["ok"] else Color(1, 0.4, 0.4))
		_ft_log_vbox.add_child(lbl)
	# Summary
	var total   = _ft_test_log.size()
	var correct = _ft_test_log.filter(func(e): return e["ok"]).size()
	var sl = Label.new()
	sl.text = "Akurasi: %d/%d (%.0f%%)" % [correct, total, float(correct) / total * 100.0]
	sl.add_theme_font_size_override("font_size", 5)
	if pixel_font: sl.add_theme_font_override("font", pixel_font)
	sl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_ft_log_vbox.add_child(sl)

# ============================================
# SESSION-BASED SPAWN SYSTEM
# ============================================
func _initialize_sessions():
	# Disable the scene Timer — we manage spawning ourselves
	var spawn_timer = get_node_or_null("Timer")
	if spawn_timer:
		spawn_timer.stop()
	
	# Prepare runtime state for all sessions
	active_sessions = []
	for i in range(SPAWN_SESSIONS.size()):
		var session = SPAWN_SESSIONS[i]
		# Each runtime entry: {index, cd_remaining, alive_count, activated}
		active_sessions.append({
			"index": i,
			"cd_remaining": 0.0,
			"alive_count": 0,
			"activated": false,
		})
	print("🎯 Session-based spawn system initialized (%d sessions)" % SPAWN_SESSIONS.size())

func _activate_new_sessions():
	for state in active_sessions:
		if state["activated"]:
			continue
		var session = SPAWN_SESSIONS[state["index"]]
		if survival_time >= session["start"]:
			state["activated"] = true
			state["cd_remaining"] = 0.0  # Spawn immediately on activation
			var minutes = int(session["start"]) / 60
			var seconds = int(session["start"]) % 60
			print("🆕 Session activated at %d:%02d — %s (cd=%.1fs, max=%d, x%d)" % [
				minutes, seconds, session["mob"], session["spawn_cd"],
				session["max_alive"], session["num_per_spawn"]
			])

func _process_spawning(delta: float):
	for state in active_sessions:
		if not state["activated"]:
			continue
		
		var session = SPAWN_SESSIONS[state["index"]]
		
		# Countdown cooldown
		state["cd_remaining"] -= delta
		if state["cd_remaining"] > 0.0:
			continue
		
		# Reset cooldown — apply fuzzy multiplier in Fuzzy Mode
		var cd = session["spawn_cd"]
		if GameManager.is_fuzzy():
			# Higher difficulty → shorter cooldown (divide by multiplier)
			cd = cd / fuzzy_difficulty
			cd = maxf(0.2, cd)
		elif survival_time > 600.0:
			# Normal mode: endless scaling after 10 min (percentage-based, more aggressive)
			var extra_minutes = (survival_time - 600.0) / 60.0
			cd = max(0.15, cd * (1.0 - extra_minutes * 0.05))
		state["cd_remaining"] = cd
		
		# Check max alive for this session — apply fuzzy scaling
		var max_alive = session["max_alive"]
		if GameManager.is_fuzzy():
			max_alive = int(max_alive * fuzzy_difficulty)
			max_alive = maxi(max_alive, 3)
		
		if state["alive_count"] >= max_alive:
			continue
		
		# Check global cap
		if total_mob_count >= MAX_TOTAL_MOBS:
			continue
		
		# Determine how many to spawn
		var num = session["num_per_spawn"]
		if GameManager.is_fuzzy():
			num = int(ceil(num * fuzzy_difficulty))
		elif survival_time > 600.0:
			# Normal mode: endless scaling after 10 min (every 1 min instead of 2)
			var extra_minutes = int((survival_time - 600.0) / 60.0)
			num += extra_minutes
		
		var space_session = max_alive - state["alive_count"]
		var space_global = MAX_TOTAL_MOBS - total_mob_count
		num = mini(num, mini(space_session, space_global))
		
		if num <= 0:
			continue
		
		# Spawn the mobs!
		_spawn_session_mobs(state, session, num)

func _spawn_session_mobs(state: Dictionary, session: Dictionary, count: int):
	var path_follow = get_node_or_null("%PathFollow2D")
	if not path_follow:
		return
	
	for i in range(count):
		# Random spawn position on the path
		path_follow.progress_ratio = randf()
		
		# Instantiate correct mob type
		var new_mob: CharacterBody2D
		match session["mob"]:
			"green":
				new_mob = MOB_GREEN.instantiate()
			"blue":
				new_mob = MOB_BLUE.instantiate()
			"red":
				new_mob = MOB_RED.instantiate()
			_:
				new_mob = MOB_GREEN.instantiate()
		
		# Apply session difficulty multipliers
		new_mob.speed *= session["speed_mult"]
		new_mob.health = int(new_mob.health * session["hp_mult"])
		
		# Set data untuk debug label
		if GameManager.is_debug():
			new_mob._mob_type         = session["mob"].to_upper()
			new_mob._base_health      = new_mob.health
			new_mob._base_speed       = new_mob.speed
			new_mob._fuzzy_mult       = fuzzy_difficulty if GameManager.is_fuzzy() else 1.0
			new_mob._session_hp_mult  = session["hp_mult"]
			new_mob._session_spd_mult = session["speed_mult"]

		# Fuzzy DDA: scale mob HP and speed based on difficulty multiplier
		# Cap fuzzy mult after menit 7 agar tidak double-stack terlalu brutal
		if GameManager.is_fuzzy():
			var eff_fuzzy = fuzzy_difficulty
			if survival_time > 420.0:
				eff_fuzzy = clampf(fuzzy_difficulty, 0.7, 1.3)
			new_mob.health = int(new_mob.health * eff_fuzzy)
			new_mob.speed *= lerpf(1.0, eff_fuzzy, 0.5)
		
		new_mob.global_position = path_follow.global_position
		
		add_child(new_mob)
		
		# Track counts
		state["alive_count"] += 1
		total_mob_count += 1
		
		# Connect death signal — decrement both session and global count
		new_mob.tree_exited.connect(_on_session_mob_killed.bind(state))



# ============================================
# NODE INITIALIZATION
# ============================================
func _initialize_nodes():
	print("🎮 Initializing game nodes...")
	
	player = get_node_or_null("%Player")
	if not player:
		player = get_node_or_null("Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if not player:
		push_error("❌ Player node not found!")
		return
	
	print("  ✅ Player found: ", player.name)
	
	# Get upgrade menu
	upgrade_menu = get_node_or_null("UpgradeMenu")
	if not upgrade_menu:
		upgrade_menu = get_tree().get_first_node_in_group("upgrade_menu")
	
	if not upgrade_menu:
		push_warning("⚠️ Upgrade menu not found!")
	else:
		print("  ✅ Upgrade menu found")
	
	# Get pause menu
	pause_menu = get_node_or_null("PauseMenu")
	if not pause_menu:
		pause_menu = get_tree().get_first_node_in_group("pause_menu")
	
	if not pause_menu:
		push_warning("⚠️ Pause menu not found!")
	else:
		print("  ✅ Pause menu found")
	
	# Get game over screen
	game_over_screen = get_node_or_null("GameOver")
	if not game_over_screen:
		game_over_screen = get_tree().get_first_node_in_group("game_over")
	
	if not game_over_screen:
		push_warning("⚠️ Game Over screen not found!")
	else:
		print("  ✅ Game Over screen found")

func _connect_signals():
	if not player:
		return
	
	print("🔗 Connecting signals...")
	
	if player.has_signal("health_depleted"):
		if not player.health_depleted.is_connected(_on_player_health_depleted):
			player.health_depleted.connect(_on_player_health_depleted)
			print("  ✅ health_depleted connected")
	
	if player.has_signal("level_up"):
		if not player.level_up.is_connected(_on_player_level_up):
			player.level_up.connect(_on_player_level_up)
			print("  ✅ level_up connected")
	
	if upgrade_menu and upgrade_menu.has_signal("upgrade_selected"):
		if not upgrade_menu.upgrade_selected.is_connected(_on_upgrade_selected):
			upgrade_menu.upgrade_selected.connect(_on_upgrade_selected)
			print("  ✅ upgrade_selected connected")
	
	print("✅ All signals connected")

func _pause_game():
	if pause_menu and pause_menu.has_method("show_pause"):
		pause_menu.show_pause()
	else:
		get_tree().paused = true

func show_level_up_menu():
	if not upgrade_menu:
		push_warning("Cannot show upgrade menu - menu not found!")
		get_tree().paused = false
		return
	
	if upgrade_menu.has_method("show_upgrades"):
		upgrade_menu.show_upgrades()
	elif upgrade_menu.has_method("show_menu"):
		upgrade_menu.show_menu()

func _on_player_level_up(new_level: int):
	print("⬆️ Player reached level ", new_level)
	show_level_up_menu()

func _on_upgrade_selected(upgrade_type: String):
	print("🔧 Applying upgrade: ", upgrade_type)
	apply_upgrade(upgrade_type)

func _on_player_health_depleted():
	print("💀 Player died!")
	game_started = false
	
	if game_over_screen:
		var player_level = player.level if player and "level" in player else 1
		
		print("📊 Game Over Stats:")
		print("  ⏱️ Survival Time: %.1f seconds" % survival_time)
		print("  ⚔️ Total Kills: %d" % total_kills)
		print("  📈 Level Reached: %d" % player_level)
		
		game_over_screen.show_game_over(survival_time, total_kills, player_level)
	else:
		push_error("Game over screen not found!")
		get_tree().paused = true

# ============================================
# UPGRADE SYSTEM (8 upgrades, balanced)
# ============================================
func apply_upgrade(upgrade_type: String):
	if not player:
		return
	
	match upgrade_type:
		"max_health":
			_upgrade_max_health()
		"health_regen":
			_upgrade_health_regen()
		"armor":
			_upgrade_armor()
		"speed":
			_upgrade_speed()
		"fire_rate":
			_upgrade_fire_rate()
		"bullet_damage":
			_upgrade_bullet_damage()
		"magnet":
			_upgrade_magnet()

func _upgrade_max_health():
	var old_max = player.max_health
	player.max_health += 20
	player.health = min(player.health + 20, player.max_health)
	_update_health_bar()
	print("💚 Max Health: ", old_max, " → ", player.max_health)

func _upgrade_health_regen():
	# Active regen: heal 5% max HP/s selama 6 detik = total 30%
	print("💚 Active Regen started: 5%% HP/s × 6s")
	_start_health_regen(6, player.max_health * 0.05)

func _start_health_regen(ticks: int, per_tick: float):
	for i in range(ticks):
		await get_tree().create_timer(1.0).timeout
		if not player or not is_instance_valid(player) or player.is_dead:
			return
		var old_hp = player.health
		player.health = minf(player.health + per_tick, player.max_health)
		_update_health_bar()
		print("💚 Regen tick %d/6: +%.0f HP (%.0f → %.0f)" % [i + 1, player.health - old_hp, old_hp, player.health])

func _upgrade_armor():
	var old_reduction = player.get_meta("damage_reduction", 0.0)
	var new_reduction = min(old_reduction + 0.15, 0.60)  # Cap at 60%
	player.set_meta("damage_reduction", new_reduction)
	print("🛡 Armor: %.0f%% → %.0f%% damage reduction" % [old_reduction * 100, new_reduction * 100])

func _upgrade_speed():
	var base_speed = 250.0
	var current_speed = player.get_meta("move_speed", base_speed)
	var new_speed = current_speed * 1.15  # +15% per level (naik dari 10%)
	player.set_meta("move_speed", new_speed)
	print("⚡ Speed: %.0f → %.0f" % [current_speed, new_speed])

func _upgrade_fire_rate():
	var gun = player.get_node_or_null("Gun")
	if not gun:
		push_warning("Gun node not found")
		return
	
	var timer = gun.get_node_or_null("Timer")
	if not timer:
		push_warning("Gun timer not found")
		return
	
	var old_wait = timer.wait_time
	timer.wait_time *= 0.75  # 25% faster
	timer.wait_time = max(timer.wait_time, 0.05)  # Min cap
	print("🔫 Fire Rate: %.3f → %.3f" % [old_wait, timer.wait_time])

func _upgrade_bullet_damage():
	var old_dmg = player.get_meta("bullet_extra_damage", 0)
	player.set_meta("bullet_extra_damage", old_dmg + 1)
	print("💥 Bullet Damage: %d → %d" % [1 + old_dmg, 2 + old_dmg])

func _upgrade_magnet():
	var base_range = 150.0  # Same as XP gem MAGNET_RADIUS
	var old_range = player.get_meta("xp_magnet_range", base_range)
	var new_range = old_range * 1.30  # +30%
	player.set_meta("xp_magnet_range", new_range)
	print("🧲 Magnet Range: %.0f → %.0f" % [old_range, new_range])


func _update_health_bar():
	var health_bar = player.get_node_or_null("%HealthBar")
	if health_bar:
		health_bar.max_value = player.max_health
		health_bar.value = player.health

# ============================================
# MOB DEATH TRACKING
# ============================================
func _on_session_mob_killed(state: Dictionary):
	state["alive_count"] = maxi(0, state["alive_count"] - 1)
	total_mob_count = maxi(0, total_mob_count - 1)
	total_kills += 1
	
	# Track kill timestamp for fuzzy DDA
	if GameManager.is_fuzzy():
		kills_window.append(survival_time)

func _on_timer_timeout():
	# Timer no longer used for spawning — sessions handle it
	pass
