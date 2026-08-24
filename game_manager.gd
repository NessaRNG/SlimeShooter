extends Node

# ============================================
# GAME MANAGER - Autoload Singleton
# ============================================
# Menyimpan mode game yang dipilih dari Main Menu
# Accessible dari mana saja via: GameManager.current_mode

enum GameMode { NORMAL, FUZZY, DEBUG }

var current_mode: GameMode = GameMode.NORMAL
var has_seen_tutorial: bool = false

func set_mode(mode: GameMode):
	current_mode = mode
	print("🎮 Game Mode set to: %s" % get_mode_name())

func get_mode_name() -> String:
	match current_mode:
		GameMode.NORMAL:
			return "Normal"
		GameMode.FUZZY:
			return "Fuzzy"
		GameMode.DEBUG:
			return "Debug"
		_:
			return "Unknown"

func is_fuzzy() -> bool:
	# Debug mode juga pakai fuzzy logic
	return current_mode == GameMode.FUZZY or current_mode == GameMode.DEBUG

func is_debug() -> bool:
	return current_mode == GameMode.DEBUG

func is_normal() -> bool:
	return current_mode == GameMode.NORMAL
