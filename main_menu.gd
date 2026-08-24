extends Control

var mode_selection_visible: bool = false
var _slime_click_count: int = 0
const _SLIME_CLICKS_NEEDED: int = 10

var _slime_node = null   # ref ke node slime, untuk cek posisi layar

func _ready():
	BGM.play_track("res://Audio/Juhani Junkala [Retro Game Music Pack] Title Screen.wav", -10.0)
	
	%PlayButton.pressed.connect(_on_play_pressed)
	%NormalButton.pressed.connect(_on_normal_pressed)
	%FuzzyButton.pressed.connect(_on_fuzzy_pressed)
	%DebugButton.pressed.connect(_on_debug_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	
	# Hover SFX
	%PlayButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	%NormalButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	%FuzzyButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	%DebugButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	%QuitButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	
	%PlayButton.grab_focus()
	
	# Diorama Animations
	var boo = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Diorama/HappyBoo")
	if boo and boo.has_method("play_walk_animation"): boo.play_walk_animation()
	
	_slime_node = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Diorama/Slime")
	if _slime_node and _slime_node.has_method("play_walk"):
		_slime_node.play_walk()

	var projectile = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Diorama/Projectile")
	if projectile:
		var tween = create_tween().set_loops()
		tween.tween_property(projectile, "position:x", 280.0, 0.4)
		tween.tween_callback(func(): projectile.position.x = 180.0)
	
	# Sembunyikan mode selection dan debug button di awal
	%ModeContainer.visible = false
	%DebugButton.visible = false
	
	_load_settings()
	_setup_settings_ui()

func _input(event):
	# Deteksi klik pada slime via posisi layar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _slime_node and is_instance_valid(_slime_node):
			# Ambil posisi slime dalam koordinat layar
			var slime_screen_pos = _slime_node.get_global_transform_with_canvas().origin
			var click_pos = event.position
			var distance = click_pos.distance_to(slime_screen_pos)
			# Radius hit ~50px (slime scale 1.2 x ~36px body)
			if distance < 50.0:
				_on_slime_clicked()
				get_viewport().set_input_as_handled()

func _on_slime_clicked():
	_slime_click_count += 1
	var remaining = _SLIME_CLICKS_NEEDED - _slime_click_count
	
	if _slime_node and _slime_node.has_method("play_hurt"):
		_slime_node.play_hurt()
	
	var subtitle = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/SubtitleLabel")
	
	if _slime_click_count >= _SLIME_CLICKS_NEEDED:
		# Unlock!
		%DebugButton.visible = true
		if subtitle:
			subtitle.text = "[DEBUG] Mode unlocked!"
			subtitle.add_theme_color_override("font_color", Color(0.3, 1.0, 1.0))
	else:
		# Hint counter samar
		if subtitle:
			subtitle.text = "...(%d)" % remaining
			subtitle.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))

func _on_play_pressed():
	SFX.play("btn_confirm")
	# Tampilkan pilihan mode
	%ModeContainer.visible = true
	%PlayButton.visible = false
	if settings_btn:
		settings_btn.visible = false
	%NormalButton.grab_focus()

func _on_normal_pressed():
	SFX.play("btn_confirm")
	GameManager.set_mode(GameManager.GameMode.NORMAL)
	SceneTransition.change_scene("res://survivors_game.tscn")

func _on_fuzzy_pressed():
	SFX.play("btn_confirm")
	GameManager.set_mode(GameManager.GameMode.FUZZY)
	SceneTransition.change_scene("res://survivors_game.tscn")

func _on_debug_pressed():
	SFX.play("btn_confirm")
	GameManager.set_mode(GameManager.GameMode.DEBUG)
	SceneTransition.change_scene("res://survivors_game.tscn")

func _on_quit_pressed():
	SFX.play("btn_back")
	get_tree().quit()

const SETTINGS_FILE = "user://settings.cfg"
var settings_popup: PanelContainer = null
var settings_btn: Button = null

func _setup_settings_ui():
	var btn_container = %PlayButton.get_parent()
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")
	
	# Create Settings Button
	settings_btn = Button.new()
	settings_btn.text = "SETTINGS"
	if pixel_font: settings_btn.add_theme_font_override("font", pixel_font)
	settings_btn.add_theme_font_size_override("font_size", 11)
	
	var normal_style = %PlayButton.get_theme_stylebox("normal").duplicate()
	normal_style.bg_color = Color(0.2, 0.4, 0.6)
	normal_style.border_color = Color(0.4, 0.6, 0.8)
	settings_btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = %PlayButton.get_theme_stylebox("hover").duplicate()
	hover_style.bg_color = Color(0.3, 0.5, 0.7)
	settings_btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = %PlayButton.get_theme_stylebox("pressed").duplicate()
	settings_btn.add_theme_stylebox_override("pressed", pressed_style)
	
	settings_btn.custom_minimum_size = Vector2(410, 54)
	
	btn_container.add_child(settings_btn)
	btn_container.move_child(settings_btn, 1) # after PlayButton
	
	settings_btn.pressed.connect(func():
		SFX.play("btn_confirm")
		
		# Sync sliders with current bus volume
		var m_idx = AudioServer.get_bus_index("Music")
		var s_idx = AudioServer.get_bus_index("SFX")
		
		settings_popup.show()
	)
	settings_btn.mouse_entered.connect(func(): SFX.play("btn_hover"))
	
	# Create Popup
	settings_popup = PanelContainer.new()
	settings_popup.hide()
	
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.05, 0.05, 0.1, 0.98)
	popup_style.border_width_left = 3
	popup_style.border_width_top = 3
	popup_style.border_width_right = 3
	popup_style.border_width_bottom = 3
	popup_style.border_color = Color(0.3, 0.6, 1.0)
	popup_style.corner_radius_top_left = 12
	popup_style.corner_radius_top_right = 12
	popup_style.corner_radius_bottom_left = 12
	popup_style.corner_radius_bottom_right = 12
	popup_style.content_margin_left = 24
	popup_style.content_margin_top = 24
	popup_style.content_margin_right = 24
	popup_style.content_margin_bottom = 24
	settings_popup.add_theme_stylebox_override("panel", popup_style)
	
	settings_popup.anchors_preset = Control.PRESET_CENTER
	settings_popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_popup.custom_minimum_size = Vector2(400, 260)
	add_child(settings_popup)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	settings_popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "SETTINGS"
	if pixel_font: title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Music Slider
	var music_box = VBoxContainer.new()
	music_box.add_theme_constant_override("separation", 8)
	var music_lbl = Label.new()
	music_lbl.text = "MUSIC VOLUME"
	if pixel_font: music_lbl.add_theme_font_override("font", pixel_font)
	music_lbl.add_theme_font_size_override("font_size", 10)
	music_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	music_box.add_child(music_lbl)
	
	var m_idx = AudioServer.get_bus_index("Music")
	var music_slider = HSlider.new()
	music_slider.min_value = 0.0001
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	if m_idx >= 0:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(m_idx))
	music_slider.value_changed.connect(func(val):
		if m_idx >= 0:
			AudioServer.set_bus_volume_db(m_idx, linear_to_db(val))
			_save_settings()
	)
	music_box.add_child(music_slider)
	vbox.add_child(music_box)
	
	# SFX Slider
	var sfx_box = VBoxContainer.new()
	sfx_box.add_theme_constant_override("separation", 8)
	var sfx_lbl = Label.new()
	sfx_lbl.text = "SFX VOLUME"
	if pixel_font: sfx_lbl.add_theme_font_override("font", pixel_font)
	sfx_lbl.add_theme_font_size_override("font_size", 10)
	sfx_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	sfx_box.add_child(sfx_lbl)
	
	var s_idx = AudioServer.get_bus_index("SFX")
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0001
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	if s_idx >= 0:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(s_idx))
	sfx_slider.value_changed.connect(func(val):
		if s_idx >= 0:
			AudioServer.set_bus_volume_db(s_idx, linear_to_db(val))
			_save_settings()
	)
	sfx_box.add_child(sfx_slider)
	vbox.add_child(sfx_box)
	
	var close_btn = Button.new()
	close_btn.text = "TUTUP"
	if pixel_font: close_btn.add_theme_font_override("font", pixel_font)
	close_btn.add_theme_font_size_override("font_size", 11)
	
	var c_norm = %PlayButton.get_theme_stylebox("normal")
	var c_hov = %PlayButton.get_theme_stylebox("hover")
	var c_pres = %PlayButton.get_theme_stylebox("pressed")
	if c_norm: close_btn.add_theme_stylebox_override("normal", c_norm.duplicate())
	if c_hov: close_btn.add_theme_stylebox_override("hover", c_hov.duplicate())
	if c_pres: close_btn.add_theme_stylebox_override("pressed", c_pres.duplicate())
	
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_child(close_btn)
	vbox.add_child(margin)
	
	close_btn.pressed.connect(func():
		SFX.play("btn_back")
		settings_popup.hide()
	)
	close_btn.mouse_entered.connect(func(): SFX.play("btn_hover"))

func _save_settings():
	var config = ConfigFile.new()
	var m_idx = AudioServer.get_bus_index("Music")
	var s_idx = AudioServer.get_bus_index("SFX")
	
	if m_idx >= 0:
		config.set_value("audio", "music", AudioServer.get_bus_volume_db(m_idx))
	if s_idx >= 0:
		config.set_value("audio", "sfx", AudioServer.get_bus_volume_db(s_idx))
		
	config.save(SETTINGS_FILE)

func _load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	if err == OK:
		var m_idx = AudioServer.get_bus_index("Music")
		var s_idx = AudioServer.get_bus_index("SFX")
		
		if m_idx >= 0:
			var music_db = config.get_value("audio", "music", 0.0)
			AudioServer.set_bus_volume_db(m_idx, music_db)
			
		if s_idx >= 0:
			var sfx_db = config.get_value("audio", "sfx", 0.0)
			AudioServer.set_bus_volume_db(s_idx, sfx_db)
