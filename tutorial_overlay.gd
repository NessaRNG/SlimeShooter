extends Node

var _canvas_layer: CanvasLayer = null
var _panel: PanelContainer = null
var _title_label: Label = null
var _text_label: Label = null
var _prev_btn: Button = null
var _next_btn: Button = null

var current_page: int = 0
var is_mobile: bool = false

var pages = [
	{
		"title": "BERGERAK",
		"text_pc": "Gunakan tombol [W A S D]\ndi keyboard untuk bergerak.",
		"text_mobile": "Sentuh dan geser area KIRI layar\n(Analog Kiri) untuk bergerak."
	},
	{
		"title": "MENEMBAK",
		"text_pc": "Gunakan [Klik Kiri] mouse\nuntuk mengarahkan dan menembak.",
		"text_mobile": "Sentuh dan geser area KANAN layar\n(Analog Kanan) untuk menembak."
	},
	{
		"title": "MEKANIK TEMBAK",
		"text_pc": "Hati-hati! Kecepatan jalanmu\nakan menurun drastis saat menembak.\n\nBerhenti menembak jika perlu berlari\ndari kejaran musuh.",
		"text_mobile": "Hati-hati! Kecepatan jalanmu\nakan menurun drastis saat menembak.\n\nBerhenti menembak jika perlu berlari\ndari kejaran musuh."
	},
	{
		"title": "PAUSE GAME",
		"text_pc": "Tekan tombol [ ESC ] di keyboard\nuntuk menjeda (Pause) game.",
		"text_mobile": "Tekan tombol [ II ] di pojok\nkanan atas layar untuk menjeda (Pause) game."
	},
	{
		"title": "NAIK LEVEL",
		"text_pc": "Kumpulkan Gem XP yang dijatuhkan musuh\nuntuk naik level dan memilih Upgrade.\n\nBertahanlah selama mungkin!",
		"text_mobile": "Kumpulkan Gem XP yang dijatuhkan musuh\nuntuk naik level dan memilih Upgrade.\n\nBertahanlah selama mungkin!"
	}
]

func setup(player_node, upgrade_menu_node) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	# Deteksi mobile persis seperti joystick
	if OS.has_feature("web"):
		var js_result = JavaScriptBridge.eval("/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);")
		if js_result:
			is_mobile = true
	else:
		if DisplayServer.is_touchscreen_available():
			is_mobile = true
			
	_create_ui()
	_update_page()

func _create_ui() -> void:
	var pixel_font = load("res://Fonts/PressStart2P-Regular.ttf")

	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "TutorialLayer"
	_canvas_layer.layer = 15
	add_child(_canvas_layer)

	_panel = PanelContainer.new()
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
	_panel.add_theme_stylebox_override("panel", popup_style)

	_panel.anchors_preset = Control.PRESET_CENTER
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(440, 340)
	_canvas_layer.add_child(_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	_panel.add_child(vbox)

	_title_label = Label.new()
	if pixel_font: _title_label.add_theme_font_override("font", pixel_font)
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_title_label.add_theme_constant_override("outline_size", 3)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	_text_label = Label.new()
	if pixel_font: _text_label.add_theme_font_override("font", pixel_font)
	_text_label.add_theme_font_size_override("font_size", 10)
	_text_label.add_theme_constant_override("line_spacing", 6)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var txt_margin = MarginContainer.new()
	txt_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	txt_margin.add_theme_constant_override("margin_top", 10)
	txt_margin.add_theme_constant_override("margin_bottom", 10)
	txt_margin.add_child(_text_label)
	vbox.add_child(txt_margin)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.35, 0.6)
	normal_style.border_color = Color(0.3, 0.6, 0.9, 0.7)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.2, 0.5, 0.8)
	hover_style.border_color = Color(0.5, 0.8, 1.0, 0.85)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.05, 0.2, 0.4)

	# Prev Button
	_prev_btn = Button.new()
	_prev_btn.text = "< KEMBALI"
	if pixel_font: _prev_btn.add_theme_font_override("font", pixel_font)
	_prev_btn.add_theme_font_size_override("font_size", 10)
	_prev_btn.add_theme_stylebox_override("normal", normal_style)
	_prev_btn.add_theme_stylebox_override("hover", hover_style)
	_prev_btn.add_theme_stylebox_override("pressed", pressed_style)
	_prev_btn.custom_minimum_size = Vector2(140, 44)
	_prev_btn.pressed.connect(func():
		SFX.play("btn_hover")
		current_page = maxi(0, current_page - 1)
		_update_page()
	)
	btn_row.add_child(_prev_btn)

	# Next Button
	_next_btn = Button.new()
	_next_btn.text = "LANJUT >"
	if pixel_font: _next_btn.add_theme_font_override("font", pixel_font)
	_next_btn.add_theme_font_size_override("font_size", 10)
	_next_btn.add_theme_stylebox_override("normal", normal_style)
	_next_btn.add_theme_stylebox_override("hover", hover_style)
	_next_btn.add_theme_stylebox_override("pressed", pressed_style)
	_next_btn.custom_minimum_size = Vector2(140, 44)
	_next_btn.pressed.connect(func():
		SFX.play("btn_hover")
		if current_page < pages.size() - 1:
			current_page += 1
			_update_page()
		else:
			_finish_tutorial()
	)
	btn_row.add_child(_next_btn)
	
	SFX.play("menu_open")

func _update_page():
	var page_data = pages[current_page]
	_title_label.text = page_data["title"] + (" (%d/%d)" % [current_page + 1, pages.size()])
	
	if is_mobile:
		_text_label.text = page_data["text_mobile"]
	else:
		_text_label.text = page_data["text_pc"]
		
	# Update buttons
	_prev_btn.visible = (current_page > 0)
	
	if current_page == pages.size() - 1:
		_next_btn.text = "MAIN SEKARANG"
		_next_btn.add_theme_color_override("font_color", Color(1, 1, 0.4))
	else:
		_next_btn.text = "LANJUT >"
		_next_btn.add_theme_color_override("font_color", Color(1, 1, 1))

func _finish_tutorial() -> void:
	SFX.play("btn_back")
	GameManager.has_seen_tutorial = true
	get_tree().paused = false
	if _canvas_layer and is_instance_valid(_canvas_layer):
		_canvas_layer.queue_free()
	queue_free()
