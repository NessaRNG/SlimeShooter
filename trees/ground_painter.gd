extends Node2D

# ============================================
# GROUND PAINTER — Decoration only
# Scatters small plant sprites on the ground
# ============================================

const PLANTS_TEX_PATH = "res://trees/Basic Plants.png"

# Green plant items from Basic Plants.png (skip index 0 = brown pot)
const PLANT_DECORS = [
	Rect2(16, 0, 16, 16),
	Rect2(32, 0, 16, 16),
	Rect2(48, 0, 16, 16),
	Rect2(64, 0, 16, 16),
]

const DECOR_CHUNK_SIZE  = 576.0
const DECOR_LOAD_RADIUS = 3
const DECORS_PER_CHUNK  = 8

var _plants_tex:   Texture2D  = null
var _decor_chunks: Dictionary = {}

func _ready() -> void:
	z_index = -98
	_plants_tex = load(PLANTS_TEX_PATH)
	if not _plants_tex:
		push_error("❌ GroundPainter: Basic Plants.png not found!")
	print("✅ GroundPainter (decorations only) ready")

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		_manage_chunks(player.global_position)

func _manage_chunks(player_pos: Vector2) -> void:
	var cw := DECOR_CHUNK_SIZE
	var cx := int(floor(player_pos.x / cw))
	var cy := int(floor(player_pos.y / cw))

	var required: Dictionary = {}
	for dx in range(-DECOR_LOAD_RADIUS, DECOR_LOAD_RADIUS + 1):
		for dy in range(-DECOR_LOAD_RADIUS, DECOR_LOAD_RADIUS + 1):
			required[Vector2(cx + dx, cy + dy)] = true

	var to_remove := []
	for coord in _decor_chunks.keys():
		if not required.has(coord):
			to_remove.append(coord)
	for coord in to_remove:
		var node = _decor_chunks[coord]
		if is_instance_valid(node):
			node.queue_free()
		_decor_chunks.erase(coord)

	for coord in required.keys():
		if not _decor_chunks.has(coord):
			_load_chunk(coord)

func _load_chunk(coord: Vector2) -> void:
	if _plants_tex == null:
		return

	var cw      := DECOR_CHUNK_SIZE
	var world_x := coord.x * cw
	var world_y := coord.y * cw

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("decor_%d_%d_v6" % [int(coord.x), int(coord.y)])

	var root := Node2D.new()
	root.position = Vector2(world_x, world_y)
	root.z_index  = -98
	add_child(root)

	var margin := 32.0
	for _i in range(DECORS_PER_CHUNK):
		var region: Rect2 = PLANT_DECORS[rng.randi() % PLANT_DECORS.size()]

		var spr := Sprite2D.new()
		spr.texture        = _plants_tex
		spr.region_enabled = true
		spr.region_rect    = region
		spr.scale          = Vector2.ONE * rng.randf_range(2.0, 3.0)
		spr.position       = Vector2(
			rng.randf_range(margin, cw - margin),
			rng.randf_range(margin, cw - margin)
		)
		spr.z_index = -98
		root.add_child(spr)

	_decor_chunks[coord] = root
