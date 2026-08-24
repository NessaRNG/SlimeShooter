extends CanvasLayer

func _ready():
	# CRITICAL: Process while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect buttons
	%ResumeButton.pressed.connect(_on_resume_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	
	# Hover SFX
	%ResumeButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	%QuitButton.mouse_entered.connect(func(): SFX.play("btn_hover"))
	
	# Hide by default
	hide()
	
	# Create help popup dynamically
	_create_help_ui()

func _input(event):
	# ESC to toggle pause
	if event.is_action_pressed("ui_cancel") and visible:
		_on_resume_pressed()

func show_pause():
	SFX.play("pause_open")
	show()
	get_tree().paused = true


func _on_resume_pressed():
	SFX.play("pause_resume")
	hide()
	get_tree().paused = false

func _on_quit_pressed():
	SFX.play("btn_back")
	# Unpause dulu sebelum change scene
	get_tree().paused = false
	# Ganti dengan main menu scene kamu
	SceneTransition.change_scene("res://main_menu.tscn")

var help_popup: PanelContainer = null

func _create_help_ui():
	# 1. Create Help Button
	var btn_container = %ResumeButton.get_parent()
	var help_btn = Button.new()
	help_btn.text = "PANDUAN / HELP"
	help_btn.add_theme_font_override("font", load("res://Fonts/PressStart2P-Regular.ttf"))
	help_btn.add_theme_font_size_override("font_size", 11)
	help_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	help_btn.add_theme_color_override("font_hover_color", Color(0.8, 0.9, 1.0))
	
	# Clone style from ResumeButton
	var normal_style = %ResumeButton.get_theme_stylebox("normal").duplicate()
	normal_style.bg_color = Color(0.1, 0.35, 0.6)
	normal_style.border_color = Color(0.3, 0.6, 0.9, 0.7)
	normal_style.shadow_color = Color(0.1, 0.4, 0.7, 0.4)
	help_btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = %ResumeButton.get_theme_stylebox("hover").duplicate()
	hover_style.bg_color = Color(0.2, 0.5, 0.8)
	hover_style.border_color = Color(0.5, 0.8, 1.0, 0.85)
	help_btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = %ResumeButton.get_theme_stylebox("pressed").duplicate()
	pressed_style.bg_color = Color(0.05, 0.2, 0.4)
	help_btn.add_theme_stylebox_override("pressed", pressed_style)
	
	help_btn.custom_minimum_size = Vector2(360, 54)
	
	btn_container.add_child(help_btn)
	btn_container.move_child(help_btn, 1)
	
	# 2. Create Help Popup
	help_popup = PanelContainer.new()
	help_popup.hide()
	
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
	help_popup.add_theme_stylebox_override("panel", popup_style)
	
	help_popup.anchors_preset = Control.PRESET_CENTER
	help_popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	help_popup.custom_minimum_size = Vector2(400, 320)
	add_child(help_popup)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	help_popup.add_child(vbox)
	
	var title = Label.new()
	title.text = "PANDUAN BERMAIN"
	title.add_theme_font_override("font", load("res://Fonts/PressStart2P-Regular.ttf"))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = "- [W A S D] atau Analog Kiri\n  Untuk Bergerak.\n\n- [Klik Kiri] atau Analog Kanan\n  Untuk Menembak.\n\n- Melambat saat menembak\n  Lepas tembakan untuk lari.\n\n- Kumpulkan Gem XP\n  Untuk naik level dan Upgrade."
	text.add_theme_font_override("font", load("res://Fonts/PressStart2P-Regular.ttf"))
	text.add_theme_font_size_override("font_size", 10)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var txt_margin = MarginContainer.new()
	txt_margin.add_theme_constant_override("margin_top", 10)
	txt_margin.add_theme_constant_override("margin_bottom", 10)
	txt_margin.add_child(text)
	vbox.add_child(txt_margin)
	
	var close_btn = Button.new()
	close_btn.text = "TUTUP"
	close_btn.add_theme_font_override("font", load("res://Fonts/PressStart2P-Regular.ttf"))
	close_btn.add_theme_font_size_override("font_size", 11)
	close_btn.add_theme_stylebox_override("normal", normal_style)
	close_btn.add_theme_stylebox_override("hover", hover_style)
	close_btn.add_theme_stylebox_override("pressed", pressed_style)
	close_btn.custom_minimum_size = Vector2(160, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(close_btn)
	
	help_btn.pressed.connect(func():
		SFX.play("btn_hover")
		help_popup.show()
	)
	close_btn.pressed.connect(func():
		SFX.play("btn_back")
		help_popup.hide()
	)
