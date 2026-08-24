extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	color_rect.position.x = 1920
	
	# Nyalakan animasi berjalan dari boneka player
	var boo = color_rect.get_node_or_null("HappyBoo")
	if boo and boo.has_method("play_walk_animation"):
		boo.play_walk_animation()

func change_scene(target_scene: String) -> void:
	print("🎬 Transitioning to: ", target_scene)
	
	# Pastikan game tidak di pause agar tween jalan
	get_tree().paused = false 
	
	# Reset posisi ke kanan layar
	color_rect.position.x = 1920
	
	# Masuk layar (Sweep In)
	SFX.play("menu_close") # Atau sound swoosh kalau ada
	var tween = create_tween()
	tween.tween_property(color_rect, "position:x", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Ganti Scene yang asli
	get_tree().change_scene_to_file(target_scene)
	
	# Jeda sejenak biar frame barunya ready
	await get_tree().create_timer(0.1).timeout
	
	# Keluar layar (Sweep Out ke Kiri)
	SFX.play("menu_open")
	var tween2 = create_tween()
	tween2.tween_property(color_rect, "position:x", -1920.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween2.finished
