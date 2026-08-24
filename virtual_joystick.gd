extends Control

@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_up: String = "move_up"
@export var action_down: String = "move_down"

var center: Vector2 = Vector2.ZERO
var stick_pos: Vector2 = Vector2.ZERO
var max_radius: float = 80.0
var deadzone: float = 0.2
var is_dragging: bool = false
var touch_index: int = -1

func _ready():
	var show_joystick = false
	if OS.has_feature("web"):
		var js_result = JavaScriptBridge.eval("/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);")
		if js_result:
			show_joystick = true
	else:
		if DisplayServer.is_touchscreen_available():
			show_joystick = true
			
	if not show_joystick:
		hide()
		set_process_input(false)
		return
		
	# custom_minimum_size = Vector2(250, 250)
	# stick_pos = size / 2

func _draw():
	if not is_dragging: return # Sembunyikan kalau tidak disentuh
	
	# Scale dinamis dari node (kita simpan di metadata game)
	var scale_factor = 3.5
	var game = get_tree().root.find_child("Game", true, false)
	if game:
		scale_factor = game.get_meta("analog_scale", 3.5)
		
	var current_radius = max_radius * scale_factor
	
	# Gambar background joystick (bulat transparan hitam)
	draw_circle(center, current_radius, Color(0, 0, 0, 0.4))
	# Gambar stick (bulat putih)
	draw_circle(stick_pos, 35.0 * scale_factor, Color(1, 1, 1, 0.7))

func _input(event):
	var game = get_tree().root.find_child("Game", true, false)
	var scale_factor = 3.5
	if game:
		scale_factor = game.get_meta("analog_scale", 3.5)
	var current_radius = max_radius * scale_factor

	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position) and touch_index == -1:
			is_dragging = true
			touch_index = event.index
			center = event.position - global_position
			stick_pos = center
			queue_redraw()
		elif not event.pressed and event.index == touch_index:
			is_dragging = false
			touch_index = -1
			_update_actions(Vector2.ZERO)
			queue_redraw()
	
	elif event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		var raw_pos = event.position - global_position
		var dir = raw_pos - center
		if dir.length() > current_radius:
			stick_pos = center + dir.normalized() * current_radius
		else:
			stick_pos = raw_pos
			
		var output = dir / current_radius
		if output.length() > 1.0:
			output = output.normalized()
			
		if output.length() < deadzone:
			output = Vector2.ZERO
		else:
			output = output.normalized() # Paksa selalu full speed seperti keyboard
			
		_update_actions(output)
		queue_redraw()

func _update_actions(vec: Vector2):
	# Simulasi tekan tombol untuk Input Map
	_set_action(action_right, vec.x > 0.1, vec.x)
	_set_action(action_left, vec.x < -0.1, -vec.x)
	_set_action(action_down, vec.y > 0.1, vec.y)
	_set_action(action_up, vec.y < -0.1, -vec.y)

func _set_action(action: String, pressed: bool, strength: float):
	if pressed:
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = true
		ev.strength = abs(strength)
		Input.parse_input_event(ev)
	else:
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = false
		ev.strength = 0.0
		Input.parse_input_event(ev)
