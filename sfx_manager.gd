extends Node

# ============================================
# SFX MANAGER — Autoload Singleton
# Panggil: SFX.play("nama_sfx")
# ============================================

const SOUNDS = {
	# UI Navigation
	"btn_hover":     "res://Audio/tick_001.ogg",
	"btn_click":     "res://Audio/click_001.ogg",
	"btn_confirm":   "res://Audio/confirmation_001.ogg",
	"btn_back":      "res://Audio/close_001.ogg",

	# Menu Events
	"menu_open":     "res://Audio/open_001.ogg",
	"menu_close":    "res://Audio/minimize_001.ogg",
	"pause_open":    "res://Audio/toggle_001.ogg",
	"pause_resume":  "res://Audio/toggle_002.ogg",

	# Gameplay Events
	"level_up":      "res://Audio/maximize_001.ogg",
	"upgrade_pick":  "res://Audio/confirmation_002.ogg",
	"game_over":     "res://Audio/error_001.ogg",
	"xp_pickup":     "res://Audio/pluck_001.ogg",
	"shoot":         "res://Audio/laser1.ogg",
	"footstep":      "res://Audio/footstep_grass_000.ogg",
	"mob_die":       "res://Audio/impactSoft_heavy_000.ogg",
}

# Pool of AudioStreamPlayer untuk multiple sounds sekaligus
const POOL_SIZE = 16
var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

func _ready() -> void:
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)

func play(sfx_name: String, volume_db: float = 0.0, randomize_pitch: bool = false) -> void:
	var path = SOUNDS.get(sfx_name, "")
	if path == "":
		push_warning("SFX: '%s' tidak ditemukan di SOUNDS dict" % sfx_name)
		return
	if not ResourceLoader.exists(path):
		push_warning("SFX: File tidak ada → %s" % path)
		return

	var player = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE

	player.stream = load(path)
	player.volume_db = volume_db
	
	if randomize_pitch:
		player.pitch_scale = randf_range(0.85, 1.15)
	else:
		player.pitch_scale = 1.0
		
	player.play()
