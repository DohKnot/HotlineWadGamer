extends Node2D

var objects = null
#export var file_path = "res://demo_levels/tiletest/level0.play"
export var file_path = "res://demo_levels/Shibuya/main0_1.play"

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
	while !f.eof_reached():
		# load basic information
		var object = int(f.get_line())
		var x = int(f.get_line())
		var y = int(f.get_line())
		var sprite = (f.get_line())
		var direction = int(f.get_line())
		var image_speed = float(f.get_line())
		
		var obj = WadSprite.new()
		if image_speed == 0 or image_speed >= 1:
			obj = Sprite.new()
		#else:
		#	print('o', object, ' s', sprite, ' i', image_speed)
		
		
		var spr_name = "sprJacketMaskPlayer"
		
		# parse object specific data
		#match GameManager.object_table[object]['parent']:
		# doors
		if 'DoorH' in GameManager.object_table[object]['name'] or 'DoorV' in GameManager.object_table[object]['name']:
			var solid = int(f.get_line())
		
		# something...
		if object == 124:
			var mystery1 = f.get_line()
			var mystery2 = f.get_line()
			var mystery3 = f.get_line()
			var mystery4 = f.get_line()
		
		# parse correct internal sprite for editor sprite
		# Make sure is valid sprite index
		if sprite in GameManager.sprite_key_table:
			# Atlases/Sprites + /Furniture/PigButcher/Party/sprELisCouchParty
			spr_name = "Atlases/Sprites" + GameManager.sprite_key_table[sprite]
			# base case
			if GameManager.env_wad.exists(spr_name + ".meta"):
				if obj is WadSprite:
					obj.frames = GameManager.env_wad.meta_sprite(spr_name + ".meta")
				else:
					obj = GameManager.env_wad.simple_sprite(spr_name + ".meta")
			# edge case garbo
			elif "/Weapons/" in GameManager.sprite_key_table[sprite]:
				# weapons
				if obj is WadSprite:
					obj.frames = GameManager.env_wad.meta_sprite("Atlases/Weapons.meta")
				else:
					obj = GameManager.env_wad.simple_sprite("Atlases/Weapons.meta")
			elif "/Enemies/" in GameManager.sprite_key_table[sprite]:
				# enemies
				var s = GameManager.sprite_key_table[sprite].substr(len("/Enemies/"), 999)
				s = s.substr(0, s.find("/"))
				# Atlases/Enemy_ + Henchman + .meta
				if obj is WadSprite:
					obj.frames = GameManager.env_wad.meta_sprite("Atlases/Enemy_" + s + ".meta")
				else:
					obj = GameManager.env_wad.simple_sprite("Atlases/Enemy_" + s + ".meta")
			elif "/PlayerCharacters/" in GameManager.sprite_key_table[sprite]:
				# only catches the player wads!! awesome
				var s = GameManager.sprite_key_table[sprite].substr(len("/PlayerCharacters/"), 999)
				s = s.substr(0, s.find("/"))
				# Atlases/Player_ + Henchman + .meta
				if obj is WadSprite:
					obj.frames = GameManager.env_wad.meta_sprite("Atlases/Player_" + s + ".meta")
				else:
					obj = GameManager.env_wad.simple_sprite("Atlases/Player_" + s + ".meta")
		else:
			#obj.frames = GameManager.env_wad.meta_sprite("Atlases/Player_Jacket.meta")
			spr_name = "sprJacketMaskPlayer"
			var obj1 = GameManager.env_wad.simple_sprite("Atlases/Player_Jacket.meta")
			add_child(obj1)
			return

		$Sprites.add_child(obj)
		obj.position = Vector2(x, y)
		obj.rotation_degrees = direction
		if obj is WadSprite:
			obj.play(spr_name.get_file())
			obj.speed_scale = image_speed
		
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
	}
	while !f.eof_reached():
		var sheet_index = int(f.get_line())
		var region = Vector2(int(f.get_line()), int(f.get_line()))
		var world_pos = Vector2(int(f.get_line()), int(f.get_line()))
		f.get_line() # depth level, unused
		var id = sheet_index * 10000 + region.x * 100 + region.y
		if sheet_index in d:
			if !(id in $TileMap.tile_set.get_tiles_ids()):
				var tex : AtlasTexture = GameManager.env_wad.simple_sprite("Atlases/Backgrounds.meta", d[sheet_index]).texture
				tex.region = Rect2(tex.region.position + region, Vector2(16,16))
				$TileMap.tile_set.create_tile(id)
				$TileMap.tile_set.tile_set_texture(id, tex)
			$TileMap.set_cellv($TileMap.world_to_map(world_pos), id)
		else:
			print("Couldn't find sheet with index: ", sheet_index)
	f.close()
