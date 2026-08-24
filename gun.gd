extends Area2D

var can_shoot = true

func _ready():
	if not $Timer.timeout.is_connected(_on_timer_timeout):
		$Timer.timeout.connect(_on_timer_timeout)
	
	$Timer.wait_time = 0.2
	$Timer.one_shot = true

func _process(_delta):
	var aim_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var is_shooting = false
	
	if aim_dir.length() > 0.1:
		# Analog / Twin stick aim
		rotation = aim_dir.angle()
		is_shooting = true
		if can_shoot:
			shoot()
	else:
		# Manual aim (Mouse) untuk PC
		look_at(get_global_mouse_position())
		
		# Block tembak manual jika sedang menyentuh layar untuk analog (bug emulate touch)
		var move_joy = get_tree().root.find_child("MoveJoystick", true, false)
		if not (move_joy and move_joy.is_dragging):
			if Input.is_action_pressed("shoot"):
				is_shooting = true
				if can_shoot:
					shoot()
	
	# Simpan state untuk dipanggil oleh player (buat ngurangin speed)
	set_meta("is_shooting", is_shooting)

func shoot():
	can_shoot = false
	SFX.play("shoot", -5.0, true)  # Added shoot sound with slight random pitch
	
	const BULLET = preload("res://bullet_2d.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.rotation = rotation
	
	# Apply upgrades from player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		new_bullet.damage = 1 + player.get_meta("bullet_extra_damage", 0)
	
	get_tree().root.add_child(new_bullet)
	
	$Timer.start()

func _on_timer_timeout():
	can_shoot = true
