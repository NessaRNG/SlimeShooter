extends Area2D

# XP gem yang di-drop musuh saat mati
# Player harus jalan deket untuk pickup

var xp_value: int = 1
var magnet_speed: float = 400.0
var is_magnetized: bool = false
var target_player: Node2D = null

const PICKUP_RADIUS = 50.0
const MAGNET_RADIUS = 150.0
const PICKUP_RADIUS_SQ = PICKUP_RADIUS * PICKUP_RADIUS
const MAGNET_RADIUS_SQ = MAGNET_RADIUS * MAGNET_RADIUS

func _ready():
	add_to_group("xp_gems")
	
	# Cari player
	target_player = get_tree().get_first_node_in_group("player")
	
	# Animasi spawn: scale bounce
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _physics_process(delta):
	if not target_player or not is_instance_valid(target_player):
		return
	
	var dist_sq = global_position.distance_squared_to(target_player.global_position)
	
	# Magnet: tarik ke player saat dalam range (upgradeable)
	var magnet_range_sq = MAGNET_RADIUS_SQ
	if target_player.has_method("get_meta"):
		var mr = target_player.get_meta("xp_magnet_range", MAGNET_RADIUS)
		magnet_range_sq = mr * mr
	if dist_sq < magnet_range_sq:
		is_magnetized = true
	
	if is_magnetized:
		var direction = global_position.direction_to(target_player.global_position)
		global_position += direction * magnet_speed * delta
		
		# Semakin dekat, semakin cepat
		magnet_speed += 600.0 * delta
	
	# Pickup: kasih XP dan hilang
	if dist_sq < PICKUP_RADIUS_SQ:
		if target_player.has_method("gain_xp"):
			target_player.gain_xp(xp_value)
		queue_free()

func set_xp(value: int):
	xp_value = value
