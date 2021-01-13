extends Node2D

var objects = null
#export var file_path = "res://demo_levels/tiletest/level0.play"
export var file_path = "res://demo_levels/Shibuya/main0_1.play"
var enemy_prefab = load("res://Enemy.tscn")

func _ready():
	# apply level mods/ folder
	var mods_path = file_path.substr(0,file_path.find_last('/')) + '/mods/'
	for f in list_files_in_directory(mods_path):
		GameManager.env_wad.apply_patchwad(mods_path+f)
	
	# tile stuff
	parse_tiles(file_path.replace(".play", ".tls"))
	# object stuff
	parse_objects(file_path)

func parse_objects(_file_path):
	# navmap setup
	$NavMap.tile_set.create_tile(0)
	#$NavMap.tile_set.tile_set_texture(0, load("res://icon.png")) # debug
	
	# Weapons.meta
	# Atlases/Player_*.meta
	# Atlases/Enemy_*.meta
	# Atlases/Sprites/*.meta
	
	# actually parsing starts
	var f = File.new()
	f.open(_file_path, File.READ)
	f.get_line()
	f.get_line()
	var file_pos = 2
	while !f.eof_reached():
		# load basic information
		var object = int(f.get_line()); file_pos += 1
		
		# rain object
		if object == 663:
			for n in range(int(f.get_line())):
				f.get_line()
				f.get_line()
				f.get_line()
				f.get_line()
				continue
		
		var x = int(f.get_line()); file_pos += 1
		var y = int(f.get_line()); file_pos += 1
		var sprite = (f.get_line()); file_pos += 1
		var direction = int(f.get_line()); file_pos += 1
		var image_speed = float(f.get_line()); file_pos += 1

		# date object
		if object == 811:
			f.get_line()
			continue

		# parse object specific data
		# doors
		if 'DoorH' in GameManager.object_table[object]['name'] or 'DoorV' in GameManager.object_table[object]['name']:
			var solid = int(f.get_line()); file_pos += 1
		
		# something...
		if object == 124:
			var mystery1 = f.get_line(); file_pos += 1
			var mystery2 = f.get_line(); file_pos += 1
			var mystery3 = f.get_line(); file_pos += 1
			var mystery4 = f.get_line(); file_pos += 1
		
		# parse correct internal sprite for editor sprite
		# Make sure is valid sprite index
		var spr_name = "sprJacketMaskPlayer"
		if sprite in GameManager.sprite_key_table:
			# Atlases/Sprites + /Furniture/PigButcher/Party/sprELisCouchParty
			spr_name = "Atlases/Sprites" + GameManager.sprite_key_table[sprite]
		else:
			spr_name = "sprJacketMaskPlayer"

		var obj = WadSprite.new()
		if "Enemies" in GameManager.object_table[object]['name']:
			print('o:',GameManager.object_table[object]['name'], ' s:', GameManager.sprite_key_table[sprite], ' i:', image_speed)
			obj = enemy_prefab.instance()
			$Enemies.add_child(obj)
			#obj.Body.play(GameManager.sprite_key_table[sprite].get_file())
			spr_name = GameManager.sprite_key_table[sprite].get_file()
			obj.init_enemy(spr_name)
			obj.position = Vector2(x, y)
			obj.direction = direction
			continue
		elif image_speed == 0 or image_speed >= 1:
			obj = Sprite.new()

		if obj is WadSprite:
			$Sprites.add_child(obj)
			obj.frames = GameManager.env_wad.meta_sprite(find_meta_name(sprite))
			obj.play(spr_name.get_file())
			obj.speed_scale = image_speed
		elif obj is Sprite:
			obj = GameManager.env_wad.simple_sprite(find_meta_name(sprite))
			$Sprites.add_child(obj)
		
		obj.position = Vector2(x, y)
		obj.rotation_degrees = direction

		match GameManager.object_table[object]['parent']:
			# walls + windows
			9:
				obj.z_index += 1
				# add to collision map
				var box = RectangleShape2D.new()
				box.extents = obj.texture.get_size()/2
				var col = CollisionShape2D.new()
				col.shape = box
				col.position = obj.position + obj.texture.get_size()/2
				$BoxCollisions.add_child(col)
				# add to nav map
				var x_range = int(obj.texture.get_size().x-1) / 16
				var y_range = int(obj.texture.get_size().y-1) / 16
				for i in range(x_range + 1):
					for j in range(y_range + 1):
						$NavMap.set_cellv($NavMap.world_to_map(obj.position + Vector2(i*16,j*16)), 0)
	f.close()

func find_meta_name(sprite):
	# parse correct internal sprite for editor sprite
	# Make sure is valid sprite index

	if sprite in GameManager.sprite_key_table:

		# base case
		# Atlases/Sprites + /Furniture/PigButcher/Party/sprELisCouchParty
		var spr_name = "Atlases/Sprites" + GameManager.sprite_key_table[sprite]
		if GameManager.env_wad.exists(spr_name + ".meta"):
			return spr_name + ".meta"

		# edge case garbo
		elif "/Weapons/" in GameManager.sprite_key_table[sprite]:
			# weapons
			return "Atlases/Weapons.meta"

		elif "/Enemies/" in GameManager.sprite_key_table[sprite]:
			# enemies
			var s = GameManager.sprite_key_table[sprite].substr(len("/Enemies/"), 999)
			s = s.substr(0, s.find("/"))
			# Atlases/Enemy_ + Henchman + .meta
			return "Atlases/Enemy_" + s + ".meta"

		elif "/PlayerCharacters/" in GameManager.sprite_key_table[sprite]:
			# only catches the player wads!! awesome
			var s = GameManager.sprite_key_table[sprite].substr(len("/PlayerCharacters/"), 999)
			s = s.substr(0, s.find("/"))
			# Atlases/Player_ + Henchman + .meta
			return "Atlases/Player_" + s + ".meta"

	#spr_name = "sprJacketMaskPlayer"
	return "Atlases/Player_Jacket.meta"

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func parse_tiles(_file_path):
	var f = File.new()
	f.open(_file_path, File.READ)
	var d = {
		2 : "Backgrounds/tlFloor",
		3 : "Backgrounds/tlAsphalt",
		6 : "Backgrounds/tlRugs",
		7 : "Backgrounds/tlTile",
		5 : "Backgrounds/tlBathroom",
		8 : "Backgrounds/tlStairs",
		47: "Backgrounds/tlTrain",
		17: "Backgrounds/tlSand",
		4 : "Backgrounds/tlDirtBlood",
		9 : "Backgrounds/tlEdges",
	}
	var depths = {
		1000 : $"1000",
		1001 : $"1001",
		-99 : $"-99",
	}
	while !f.eof_reached():
		var tst = f.get_line()
		if tst == '':
			break
		var sheet_index = int(tst)
		var region = Vector2(int(f.get_line()), int(f.get_line()))
		var world_pos = Vector2(int(f.get_line()), int(f.get_line()))
		var depth = int(f.get_line())
		var id = sheet_index * 10000 + region.x * 100 + region.y
		if depth in depths:
			if sheet_index in d:
				var tilemap = depths[depth]
				if !(id in tilemap.tile_set.get_tiles_ids()):
					var tex : AtlasTexture = GameManager.env_wad.simple_sprite("Atlases/Backgrounds.meta", d[sheet_index]).texture
					tex.region = Rect2(tex.region.position + region, Vector2(16,16))
					for t in depths.values():
						t.tile_set.create_tile(id)
						t.tile_set.tile_set_texture(id, tex)
				tilemap.set_cellv(tilemap.world_to_map(world_pos), id)
			else:
				print("Couldn't find sheet with index: ", sheet_index)
	f.close()
