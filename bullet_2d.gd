extends Area2D

const DmgNum = preload("res://damage_number.gd")

var travelled_distance = 0
const SPEED = 1000
const RANGE = 1200

# Upgrade-able stats
var damage: int = 1
var pierce_remaining: int = 0  # 0 = no pierce (destroy on hit)

func _physics_process(delta):
	# Bergerak sesuai rotasi yang sudah di-set
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_spawn_damage_number(body.global_position, damage)
	
	if pierce_remaining > 0:
		pierce_remaining -= 1
	else:
		queue_free()

func _spawn_damage_number(pos: Vector2, dmg: int) -> void:
	var node := Node2D.new()
	node.set_script(DmgNum)
	node.setup(dmg, pos)
	get_tree().current_scene.add_child(node)
