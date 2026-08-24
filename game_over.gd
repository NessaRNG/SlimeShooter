extends CanvasLayer

# ⚙️ CONFIG: Ganti dengan path scene game kamu!
const GAME_SCENE_PATH = "res://survivors_game.tscn"  # ← SESUAIKAN PATH INI!

func _ready():
	add_to_group("game_over")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused
	
	# Connect buttons setelah ready
	call_deferred("_connect_buttons")

func _connect_buttons():
	print("🔗 Connecting Game Over buttons...")
	
	# Connect Retry button
	var retry_btn = get_node_or_null("%RetryButton")
	if retry_btn:
		if not retry_btn.pressed.is_connected(_on_retry_pressed):
			retry_btn.pressed.connect(_on_retry_pressed)
			print("  ✅ RetryButton connected")
	else:
		push_error("  ❌ RetryButton not found!")
	
	# Connect Quit button
	var quit_btn = get_node_or_null("%QuitButton")
	if quit_btn:
		if not quit_btn.pressed.is_connected(_on_quit_pressed):
			quit_btn.pressed.connect(_on_quit_pressed)
			print("  ✅ QuitButton connected")
	else:
		push_error("  ❌ QuitButton not found!")
		
	# Connect Form button
	var form_btn = get_node_or_null("%FormButton")
	if form_btn:
		if not form_btn.pressed.is_connected(_on_form_pressed):
			form_btn.pressed.connect(_on_form_pressed)
			print("  ✅ FormButton connected")
	else:
		push_error("  ❌ FormButton not found!")
		
	# Connect Switch Mode button
	var switch_btn = get_node_or_null("%SwitchModeButton")
	if switch_btn:
		if not switch_btn.pressed.is_connected(_on_switch_mode_pressed):
			switch_btn.pressed.connect(_on_switch_mode_pressed)
			print("  ✅ SwitchModeButton connected")
	else:
		push_error("  ❌ SwitchModeButton not found!")
		
	# Hover SFX
	if retry_btn: retry_btn.mouse_entered.connect(func(): SFX.play("btn_hover"))
	if quit_btn: quit_btn.mouse_entered.connect(func(): SFX.play("btn_hover"))
	if form_btn: form_btn.mouse_entered.connect(func(): SFX.play("btn_hover"))
	if switch_btn: switch_btn.mouse_entered.connect(func(): SFX.play("btn_hover"))


func show_game_over(time_survived: float, enemies_killed: int, level_reached: int):
	print("📊 Showing Game Over Screen")
	SFX.play("game_over")
	_show_end_screen("GAME OVER", Color(0.86, 0.31, 0.31), time_survived, enemies_killed, level_reached)

func show_victory(time_survived: float, enemies_killed: int, level_reached: int):
	print("🏆 Showing Victory Screen")
	SFX.play("menu_open")
	_show_end_screen("YOU SURVIVED!", Color(0.42, 0.81, 0.49), time_survived, enemies_killed, level_reached)

func _show_end_screen(title: String, title_color: Color, time_survived: float, enemies_killed: int, level_reached: int):
	# Show menu
	visible = true
	
	# Pause game
	get_tree().paused = true
	
	# Update title
	var title_label = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/TitleLabel")
	if title_label:
		title_label.text = title
		title_label.add_theme_color_override("font_color", title_color)
	
	# Update stats label
	var stats_label = get_node_or_null("%StatsLabel")
	if stats_label:
		var mode_name = GameManager.get_mode_name()
		var stats_text = "Mode: %s\nTime Survived: %d seconds\nEnemies Killed: %d\nLevel Reached: %d" % [
			mode_name,
			int(time_survived),
			enemies_killed,
			level_reached
		]
		
		var game = get_tree().get_first_node_in_group("game")
		
		if GameManager.is_fuzzy():
			# Fuzzy Mode: tampilkan rata-rata difficulty multiplier
			if game and game.has_method("get_fuzzy_average_difficulty"):
				var avg_diff = game.get_fuzzy_average_difficulty()
				stats_text += "\nAvg Fuzzy Difficulty: %.2f" % avg_diff
		else:
			# Normal Mode: tampilkan stage yang berhasil dicapai
			if game and game.has_method("get_normal_difficulty_info"):
				var info = game.get_normal_difficulty_info()
				stats_text += "\nDifficulty Stage Reached: %s" % info[0]
		
		stats_label.text = stats_text
	else:
		push_warning("StatsLabel not found!")
		
	var switch_btn = get_node_or_null("%SwitchModeButton")
	if switch_btn:
		if GameManager.is_fuzzy():
			switch_btn.text = "> REPLAY IN NORMAL MODE"
		else:
			switch_btn.text = "> REPLAY IN FUZZY MODE"

func _on_retry_pressed():
	print("🔄 RETRY BUTTON PRESSED")
	SFX.play("btn_confirm")
	
	# Step 1: Unpause game
	print("  1. Unpausing game...")
	get_tree().paused = false
	
	# Step 2: Hide menu
	print("  2. Hiding game over menu...")
	visible = false
	
	# Step 3: Change scene dengan call_deferred (ANTI-FREEZE!)
	print("  3. Changing scene to: ", GAME_SCENE_PATH)
	SceneTransition.change_scene(GAME_SCENE_PATH)
	
	print("  ✅ Retry initiated!")

func _on_quit_pressed():
	print("🏠 MAIN MENU BUTTON PRESSED")
	SFX.play("btn_back")
	
	# Unpause dulu
	get_tree().paused = false
	
	# Kembali ke main menu
	SceneTransition.change_scene("res://main_menu.tscn")

func _on_form_pressed():
	print("📝 FORM BUTTON PRESSED")
	SFX.play("btn_confirm")
	OS.shell_open("https://forms.gle/mv6ACBqUiuLeRguB7")

func _on_switch_mode_pressed():
	print("🔄 SWITCH MODE BUTTON PRESSED")
	SFX.play("btn_confirm")
	
	if GameManager.is_fuzzy():
		GameManager.set_mode(GameManager.GameMode.NORMAL)
	else:
		GameManager.set_mode(GameManager.GameMode.FUZZY)
		
	get_tree().paused = false
	visible = false
	SceneTransition.change_scene(GAME_SCENE_PATH)
