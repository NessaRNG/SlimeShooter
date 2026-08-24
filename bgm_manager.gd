extends Node

var target_bgm_path = ""

func _ready():
	var player = AudioStreamPlayer.new()
	player.name = "BGMPlayer"
	player.bus = "Music"
	player.process_mode = Node.PROCESS_MODE_ALWAYS # Keep playing when game gets paused for upgrades
	player.finished.connect(player.play) # Auto-loop! 
	add_child(player)

func play_track(path: String, volume_db: float = -10.0):
	# Don't restart if already playing the exact same track
	if target_bgm_path == path:
		return 
		
	var player = $BGMPlayer
	if player.playing:
		player.stop()
		
	target_bgm_path = path
	if path != "":
		if ResourceLoader.exists(path):
			player.stream = load(path)
			player.volume_db = volume_db
			player.play()
		else:
			push_warning("BGM File not found: " + path)

func stop():
	target_bgm_path = ""
	$BGMPlayer.stop()
