extends SceneTree

func _init():
	print("--- CLEAN ASSETS SCRIPT ---")
	var referenced_files = {}
	
	# 1. Cari semua res:// di .tscn, .gd, .tres
	var dirs_to_check = ["res://"]
	while dirs_to_check.size() > 0:
		var dir_path = dirs_to_check.pop_front()
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not file_name.begins_with("."):
					if dir.current_is_dir():
						if file_name != "addons" and file_name != ".godot":
							dirs_to_check.append(dir_path + file_name + "/")
					else:
						var ext = file_name.get_extension().to_lower()
						if ext in ["tscn", "gd", "tres", "json"]:
							var file_path = dir_path + file_name
							var f = FileAccess.open(file_path, FileAccess.READ)
							if f:
								var content = f.get_as_text()
								# Simple regex-like extraction since Godot's RegEx is standard
								var regex = RegEx.new()
								regex.compile("res://[^\\s\\\"\\'\\)]+")
								for result in regex.search_all(content):
									referenced_files[result.get_string()] = true
				file_name = dir.get_next()
				
	print("Found references: ", referenced_files.size())
	
	# 2. Cari semua gambar/audio
	var asset_exts = ["png", "svg", "wav", "ogg"]
	var all_assets = []
	
	dirs_to_check = ["res://"]
	while dirs_to_check.size() > 0:
		var dir_path = dirs_to_check.pop_front()
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not file_name.begins_with("."):
					if dir.current_is_dir():
						if file_name != "addons" and file_name != ".godot":
							dirs_to_check.append(dir_path + file_name + "/")
					else:
						var ext = file_name.get_extension().to_lower()
						if ext in asset_exts:
							var file_path = dir_path + file_name
							
							# Perbaiki bug path ganda seperti res://icons/file.png
							file_path = file_path.replace("///", "//")
							all_assets.append(file_path)
				file_name = dir.get_next()
				
	print("Total assets: ", all_assets.size())
	
	# 3. Cari yang gak dipakai
	var unused = []
	for asset in all_assets:
		if not referenced_files.has(asset):
			# Hapus file yang tidak terpakai
			var path_to_del = ProjectSettings.globalize_path(asset)
			DirAccess.remove_absolute(path_to_del)
			unused.append(asset)
			
	print("Deleted ", unused.size(), " unused assets.")
	
	quit()
