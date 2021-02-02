extends Node2D

var objects = null
#export var file_path = "res://demo_levels/tiletest/level0.play"
export var file_path = "res://demo_levels/Shibuya/main0_0.play"
var enemy_prefab = preload("res://Enemy.tscn")

var sprite_meta_table_cache = {}


func _ready():
	# apply level mods/ folder
	var levels_path = file_path.substr(0,file_path.find_last('/'))+'/'
	for f in list_files_in_directory(levels_path):
		if '.play' in f and !("outro" in f) and !("intro" in f):
			if !(levels_path + f in GameManager.lvl_cache):
				GameManager.lvl_cache[levels_path + f] = false

	var sum = 0
	for a in GameManager.lvl_cache.values():
		sum += int(a)
	if sum == len(GameManager.lvl_cache.values()):
		for a in GameManager.lvl_cache.keys():
			GameManager.lvl_cache[a] = false

	for f in GameManager.lvl_cache.keys():
		if !GameManager.lvl_cache[f]:
			file_path = f
			break

	GameManager.lvl_cache[file_path] = true
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
	$NavMap.tile_set.tile_set_texture(0, load("res://icon16x16.png")) # debug
	$NavMap.tile_set.create_tile(1)
	$NavMap.tile_set.tile_set_texture(1, load("res://icon16x16.png")) # debug
	$NavMap.tile_set.create_tile(2)
	$NavMap.tile_set.tile_set_texture(2, load("res://icon16x16.png")) # debug
	
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
	var farthest_position_from_origin = Vector2.ZERO
	while !f.eof_reached():
		# load basic information
		var tst = f.get_line()
		if tst == '':
			break
		var object = int(tst); file_pos += 1
		
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
		farthest_position_from_origin = Vector2(max(x, farthest_position_from_origin.x), max(y, farthest_position_from_origin.y))
		var sprite = (f.get_line()); file_pos += 1
		var direction = int(f.get_line()); file_pos += 1
		var image_speed = 0
		if object != 2411:
			image_speed = float(f.get_line()); file_pos += 1

		# date object		elevator obj
		if object == 811 or object == 810:
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
			#print('o:',GameManager.object_table[object]['name'], ' s:', GameManager.sprite_key_table[sprite], ' i:', image_speed)
			obj = enemy_prefab.instance()
			$Enemies.add_child(obj)
			#obj.Body.play(GameManager.sprite_key_table[sprite].get_file())
			spr_name = GameManager.sprite_key_table[sprite].get_file()
			obj.init_enemy(spr_name)
			obj.position = Vector2(x, y)
			obj.direction = direction
			continue
		elif GameManager.object_table[object]['parent'] == 9:
			obj = GameManager.shadow_prefab.instance()
			#obj = GameManager.env_wad.simple_sprite(find_meta_name(sprite))
		elif image_speed == 0 or image_speed >= 1:
			obj = Sprite.new()

		if obj is WadSprite:
			$Sprites.add_child(obj)
			obj.frames = GameManager.env_wad.meta_sprite(find_meta_name(sprite))
			obj.play(spr_name.get_file())
			obj.speed_scale = image_speed
		elif obj is Sprite:
			var l = GameManager.env_wad.single_frame(find_meta_name(sprite))
			obj.texture = l[0]
			obj.offset = l[1]
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
	$NavMap.obstacles = $NavMap.get_used_cells_by_id(0)
	$NavMap.map_size = Vector2(
		int(farthest_position_from_origin.x / 16),
		int(farthest_position_from_origin.y / 16)
	)
	$NavMap._ready()
	f.close()

func find_meta_name(sprite):
	# parse correct internal sprite for editor sprite
	# Make sure is valid sprite index
	if sprite in sprite_meta_table_cache:
		return sprite_meta_table_cache[sprite]
	
	var found_meta = "Atlases/Player_Jacket.meta"

	if sprite in GameManager.sprite_key_table:

		# base case
		# Atlases/Sprites + /Furniture/PigButcher/Party/sprELisCouchParty
		var spr_name = "Atlases/Sprites" + GameManager.sprite_key_table[sprite]
		if GameManager.env_wad.exists(spr_name + ".meta"):
			found_meta = spr_name + ".meta"

		# edge case garbo
		elif "/Weapons/" in GameManager.sprite_key_table[sprite]:
			# weapons
			found_meta = "Atlases/Weapons.meta"

		elif "/Enemies/" in GameManager.sprite_key_table[sprite]:
			# enemies
			var s = GameManager.sprite_key_table[sprite].substr(len("/Enemies/"), 999)
			s = s.substr(0, s.find("/"))
			# Atlases/Enemy_ + Henchman + .meta
			found_meta = "Atlases/Enemy_" + s + ".meta"

		elif "/PlayerCharacters/" in GameManager.sprite_key_table[sprite]:
			# only catches the player wads!! awesome
			var s = GameManager.sprite_key_table[sprite].substr(len("/PlayerCharacters/"), 999)
			s = s.substr(0, s.find("/"))
			# Atlases/Player_ + Henchman + .meta
			found_meta = "Atlases/Player_" + s + ".meta"

	sprite_meta_table_cache[sprite] = found_meta
	return found_meta

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
						if !(id in t.tile_set.get_tiles_ids()):
							t.tile_set.create_tile(id)
							t.tile_set.tile_set_texture(id, tex)
				tilemap.set_cellv(tilemap.world_to_map(world_pos), id)
			#else:
			#	print("Couldn't find sheet with index: ", sheet_index)
	f.close()
