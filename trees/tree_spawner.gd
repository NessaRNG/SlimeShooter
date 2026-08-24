extends Node2D

const TREE_SCENE = preload("res://trees/pine_tree.tscn")

# Spawn settings
const CHUNK_SIZE = 1200.0  
const SPAWN_CHUNK_RADIUS = 2 # Load 2 chunks in every direction (5x5 grid)
const TREES_PER_CHUNK = 7 # Diubah jadi 7 (sebelumnya 12 terus 4) biar pas di tengah
const MIN_DISTANCE_BETWEEN_TREES = 225.0 # Diubah jadi 225 (sebelumnya 150 terus 300)

var player: Node2D
# active_chunks menyimpan array references ke pohon-pohon yang ada di chunk tersebut
var active_chunks: Dictionary = {} # Kunci: Vector2 (chunk_coord), Value: Array[Node2D]

func _ready():
	print("🌲 Procedural Tree Spawner Initialized")
	# Cari player
	player = get_node_or_null("%Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
		
	if not player:
		push_warning("⚠️ Player not found for tree spawner!")

func _process(_delta):
	if not player or not is_instance_valid(player):
		return
		
	_manage_chunks()

func _manage_chunks():
	var player_pos = player.global_position
	
	# Hitung koordinat chunk player saat ini
	var current_chunk_x = floor(player_pos.x / CHUNK_SIZE)
	var current_chunk_y = floor(player_pos.y / CHUNK_SIZE)
	var current_coord = Vector2(current_chunk_x, current_chunk_y)
	
	# Determine which chunks should be active
	var required_chunks = []
	for x in range(current_chunk_x - SPAWN_CHUNK_RADIUS, current_chunk_x + SPAWN_CHUNK_RADIUS + 1):
		for y in range(current_chunk_y - SPAWN_CHUNK_RADIUS, current_chunk_y + SPAWN_CHUNK_RADIUS + 1):
			required_chunks.append(Vector2(x, y))
	
	# 1. Unload chunks that are too far
	var chunks_to_remove = []
	for chunk_coord in active_chunks.keys():
		if not chunk_coord in required_chunks:
			_unload_chunk(chunk_coord)
			chunks_to_remove.append(chunk_coord)
			
	for chunk_coord in chunks_to_remove:
		active_chunks.erase(chunk_coord)
		
	# 2. Load missing chunks
	for chunk_coord in required_chunks:
		if not active_chunks.has(chunk_coord):
			_load_chunk(chunk_coord)

func _load_chunk(chunk_coord: Vector2):
	var chunk_trees = []
	active_chunks[chunk_coord] = chunk_trees
	
	# Deterministic random based on chunk coordinate + arbitrary game seed (12345)
	var chunk_seed = hash(str(chunk_coord.x) + "_" + str(chunk_coord.y) + "_tree_seed_12345")
	var rng = RandomNumberGenerator.new()
	rng.seed = chunk_seed
	
	# Hitung batas area chunk ini
	var start_x = chunk_coord.x * CHUNK_SIZE
	var start_y = chunk_coord.y * CHUNK_SIZE
	
	var num_trees = rng.randi_range(TREES_PER_CHUNK - 4, TREES_PER_CHUNK + 4)
	var tree_positions = []
	
	for i in range(num_trees):
		var tree_x = start_x + rng.randf_range(0, CHUNK_SIZE)
		var tree_y = start_y + rng.randf_range(0, CHUNK_SIZE)
		var tree_pos = Vector2(tree_x, tree_y)
		
		# Jaga jarak antar pohon
		var too_close = false
		for other_pos in tree_positions:
			if tree_pos.distance_to(other_pos) < MIN_DISTANCE_BETWEEN_TREES:
				too_close = true
				break
				
		if not too_close:
			tree_positions.append(tree_pos)
			
			var tree = TREE_SCENE.instantiate()
			tree.global_position = tree_pos
			
			# Variasi ukuran skala antara 0.9 sampai 1.4
			var random_scale = rng.randf_range(0.9, 1.4)
			var sprite = tree.get_node_or_null("PineTree")
			var collision = tree.get_node_or_null("CollisionShape2D")
			var shadow = tree.get_node_or_null("GroundShadow")
			
			if sprite:
				sprite.scale = Vector2(random_scale * 1.25, random_scale * 1.25)
			if collision:
				# Scale up the collision radius
				var shape = collision.shape.duplicate()
				shape.radius *= random_scale
				collision.shape = shape
			if shadow:
				shadow.scale *= random_scale
				
			add_child(tree)
			chunk_trees.append(tree)

func _unload_chunk(chunk_coord: Vector2):
	var chunk_trees = active_chunks[chunk_coord]
	for tree in chunk_trees:
		if is_instance_valid(tree):
			tree.queue_free()

