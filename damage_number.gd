extends Node2D

# ============================================
# DAMAGE NUMBER — floating popup saat hit
# Spawn di posisi musuh, float ke atas, fade out
# ============================================

const FONT_PATH = "res://Fonts/PressStart2P-Regular.ttf"

var _value: int = 1
var _timer: float = 0.0
const LIFETIME    = 0.8   # detik sebelum hilang
const FLOAT_SPEED = 60.0  # world units per detik ke atas
const FONT_SIZE   = 8

func setup(dmg: int, pos: Vector2) -> void:
	_value = dmg
	global_position = pos + Vector2(randf_range(-12, 12), -20)
	z_index = 200

func _ready() -> void:
	var label := Label.new()
	label.name = "DmgLabel"
	label.text = str(_value)

	var font = load(FONT_PATH)
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", FONT_SIZE)

	# Warna berdasarkan damage amount
	var col: Color
	if _value >= 3:
		col = Color(1.0, 0.3, 0.3)   # merah — big hit
	elif _value == 2:
		col = Color(1.0, 0.75, 0.2)  # oranye — medium
	else:
		col = Color(1.0, 1.0, 1.0)   # putih — normal

	label.add_theme_color_override("font_color", col)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -8)
	add_child(label)

func _process(delta: float) -> void:
	_timer += delta
	var progress = _timer / LIFETIME   # 0.0 → 1.0

	# Float naik
	position.y -= FLOAT_SPEED * delta

	# Scale: muncul besar lalu kecil
	var s = lerp(1.3, 0.7, progress)
	scale = Vector2(s, s)

	# Fade out di paruh akhir
	var alpha = 1.0 - clampf((progress - 0.4) / 0.6, 0.0, 1.0)
	modulate.a = alpha

	if _timer >= LIFETIME:
		queue_free()
