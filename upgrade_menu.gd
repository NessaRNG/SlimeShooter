extends CanvasLayer

signal upgrade_selected(upgrade_type: String)

# ============================================
# UPGRADE DATABASE
# ============================================
const UPGRADES = {
	"max_health": {
		"name": "Max Health",
		"description": "+20 Max HP",
		"category": "DEF",
		"max_level": 5,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/half-heart.svg",
	},
	"health_regen": {
		"name": "Regeneration",
		"description": "+5% HP/s (6s)",
		"category": "DEF",
		"max_level": 3,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/bandaged.svg",
	},
	"armor": {
		"name": "Armor",
		"description": "-15% Dmg Taken",
		"category": "DEF",
		"max_level": 4,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/armor-vest.svg",
	},
	"fire_rate": {
		"name": "Fire Rate",
		"description": "+25% Atk Spd",
		"category": "ATK",
		"max_level": 5,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/autogun.svg",
	},
	"bullet_damage": {
		"name": "Bullet Dmg",
		"description": "+1 Damage",
		"category": "ATK",
		"max_level": 5,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/bullets.svg",
	},
	"speed": {
		"name": "Move Speed",
		"description": "+15% Speed",
		"category": "UTL",
		"max_level": 4,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/sprint.svg",
	},
	"magnet": {
		"name": "XP Magnet",
		"description": "+30% Pickup",
		"category": "UTL",
		"max_level": 3,
		"icon": "res://icons-white/ffffff/transparent/1x1/lorc/magnet.svg",
	},
}

const CATEGORY_COLORS = {
	"DEF": Color(0.3, 0.85, 0.5),
	"ATK": Color(1.0, 0.38, 0.35),
	"UTL": Color(0.4, 0.72, 1.0),
}

var upgrade_levels: Dictionary = {}
var current_upgrades = []

@onready var panel_anim = $CenterContainer

# Arrays of card refs — populated in _ready() from CardsRow/Card1..3
var _cards: Array = []
var _icons: Array = []
var _cat_labels: Array = []
var _name_labels: Array = []
var _desc_labels: Array = []
var _stars_labels: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	var row = $CenterContainer/VBox/CardsRow
	for i in range(1, 4):
		var card = row.get_node("Card%d" % i)
		var vbox = card.get_node("Vbox")
		_cards.append(card)
		_icons.append(vbox.get_node("IconRect"))
		_cat_labels.append(vbox.get_node("CatLabel"))
		_name_labels.append(vbox.get_node("NameLabel"))
		_desc_labels.append(vbox.get_node("DescLabel"))
		_stars_labels.append(vbox.get_node("StarsLabel"))
		card.pressed.connect(_on_choose_pressed.bind(i - 1))
		card.mouse_entered.connect(func(): SFX.play("btn_hover"))

	for key in UPGRADES.keys():
		upgrade_levels[key] = 0

	hide()

func _setup_card(idx: int, upgrade_key: String):
	var data = UPGRADES[upgrade_key]
	var lv = upgrade_levels[upgrade_key]
	var max_lv = data["max_level"]
	var cat = data["category"]
	var cat_color = CATEGORY_COLORS.get(cat, Color(1, 1, 1))

	# Category badge
	_cat_labels[idx].text = "[ %s ]" % cat
	_cat_labels[idx].add_theme_color_override("font_color", cat_color)

	# Name
	_name_labels[idx].text = data["name"]

	# Description
	_desc_labels[idx].text = data["description"]
	_desc_labels[idx].add_theme_color_override("font_color", cat_color.lerp(Color(1, 1, 1), 0.35))

	# Stars level indicator
	var stars = ""
	for i in range(max_lv):
		stars += ("* " if i < lv else "- ")
	_stars_labels[idx].text = stars.strip_edges()
	_stars_labels[idx].add_theme_color_override("font_color", cat_color)

	# Icon
	_icons[idx].texture = null
	var icon_path = data.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_icons[idx].texture = load(icon_path)

	_cards[idx].visible = true

func show_upgrades():
	var available = []
	for key in UPGRADES.keys():
		if upgrade_levels[key] < UPGRADES[key]["max_level"]:
			available.append(key)

	if available.size() == 0:
		available.append("health_regen")

	available.shuffle()
	var num = mini(3, available.size())
	current_upgrades = available.slice(0, num)

	for i in range(3):
		if i < num:
			_setup_card(i, current_upgrades[i])
		else:
			_cards[i].visible = false

	panel_anim.modulate.a = 0
	show()
	SFX.play("menu_open")

	var tween = create_tween()
	tween.tween_property(panel_anim, "modulate:a", 1.0, 0.28)

func _on_choose_pressed(idx: int):
	if idx >= current_upgrades.size():
		return

	SFX.play("upgrade_pick")
	var upgrade_type = current_upgrades[idx]
	upgrade_levels[upgrade_type] += 1
	print("⬆️ %s → Lv.%d/%d" % [
		UPGRADES[upgrade_type]["name"],
		upgrade_levels[upgrade_type],
		UPGRADES[upgrade_type]["max_level"]
	])

	var fade = create_tween()
	fade.tween_property(panel_anim, "modulate:a", 0.0, 0.22)
	await fade.finished

	hide()
	upgrade_selected.emit(upgrade_type)
	get_tree().paused = false

func get_upgrade_level(upgrade_key: String) -> int:
	return upgrade_levels.get(upgrade_key, 0)
