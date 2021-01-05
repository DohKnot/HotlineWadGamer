extends File

class_name Wad

#var file_list = []
var file_locations = {}
var patchwad_list = []
var content_offset = -1

var sprite_centers : PoolStringArray = []

var loaded_sheets = {}
var loaded_atlases = {}
var loaded_metas = {}
var loaded_simples = {}


func parse_header():
	# skip wad identifier for now
	seek(0x10)
	
	# parse file locations
	var num_files = get_32()
	file_locations.clear()
	#file_list.clear()
	for _i in range(num_files):
		# metadata
		var file_name_l = get_32();
		var file_name = get_buffer(file_name_l).get_string_from_ascii()
		var file_len = get_64()
		var file_offset = get_64()
		# add to file locations
		file_locations[file_name] = [file_offset, file_len]
		#file_list.append(file_name)
		
	# parse directories (unused but maybe useful later?)
	var _num_dirs = get_32()
	for _i in range(_num_dirs):
		var _dir_name_l = get_32()
		var _dir_name = get_buffer(_dir_name_l)#.get_string_from_ascii()
		var _num_entries = get_32()
		for _j in range(_num_entries):
			var _entry_name_l = get_32()
			var _entry_name = get_buffer(_entry_name_l)
			var _entry_type = get_8()
	
	# raw file data starts here
	content_offset = get_position()
	
	# get sprite centers
	var f = File.new()
	f.open("res://sprite_centers.txt", File.READ)
	sprite_centers = f.get_as_text().split('\n')

func exists(asset_name):
	return asset_name in file_locations.keys()

func lazy_find(asset_name):
	for k in file_locations.keys():
		if asset_name == k.get_file():
			return k
	return asset_name

func get(asset):
	for p in patchwad_list:
		if p.exists(asset):
			return p.get(asset)
	var dim = file_locations[asset]
	seek(content_offset + dim[0])
	return get_buffer(dim[1])

func apply_patchwad(f):
	var patchwad = get_script().new()
	patchwad.open(f, File.READ)
	patchwad.parse_header()
	patchwad_list.append(patchwad)

func sprite_sheet(asset, lazy=0):
	if lazy:
		asset = lazy_find(asset)
	if asset in loaded_sheets.keys():
		return loaded_sheets[asset]
	var img = Image.new()
	img.load_png_from_buffer(get(asset))
	var tex = ImageTexture.new()
	tex.create_from_image(img, 0)
	loaded_sheets[asset] = tex
	return tex

func byte_array_to_int(bytes):
		return ((bytes[3] & 0xFF) << 24) | ((bytes[2] & 0xFF) << 16) | ((bytes[1] & 0xFF) << 8) | ((bytes[0] & 0xFF) << 0)

# rename animated_sprite
func meta_sprite(asset, lazy=0):
	if lazy:
		asset = lazy_find(asset)
	if asset in loaded_metas.keys():
		return loaded_metas[asset]
	var tex = sprite_sheet(asset.replace(".meta", ".png"), lazy)

	var buffer = get(asset)
	var sprites : WadFrames = WadFrames.new()
	sprites.remove_animation("default")
	var position = 0x10 + 0x04 + 0x04
	
	while (position < len(buffer)):
		# parse sprite name
		var sprite_name_l = buffer[position]
		position += 1
		var sprite_name = buffer.subarray(position, position+sprite_name_l-1).get_string_from_ascii()
		sprites.add_animation(sprite_name)
		
		# parse frames
		position += sprite_name_l
		var image_count = byte_array_to_int(buffer.subarray(position, position+4))
		position += 4
		var ref_region = null
		for i in range(image_count):
			position += 4
			var img = AtlasTexture.new()
			ref_region = Rect2(
				byte_array_to_int(buffer.subarray(position+8, position+8+4)),
				byte_array_to_int(buffer.subarray(position+12, position+12+4)),
				byte_array_to_int(buffer.subarray(position, position+4)),
				byte_array_to_int(buffer.subarray(position+4, position+4+4))
			);
			img.region = ref_region
			img.atlas = tex
			position += 32
			sprites.add_frame(sprite_name, img)
			sprites.set_animation_speed(sprite_name, 60)
		if ref_region != null and sprite_name in sprite_centers:
			for i in range(0, len(sprite_centers), 3):
				if sprite_centers[i] == sprite_name:
					sprites.centers[sprite_name] = ref_region.size/2 - Vector2(
						int(sprite_centers[i+1]),
						int(sprite_centers[i+2])
					)
		else:
			sprites.centers[sprite_name] = Vector2(0, 0)
	#print(sprites.get_animation_names())
	#print(img)
		#sprites.append(new MetaSprite(spriteName, images, GetSpriteOffset(spriteName)));
		#sprites.append({
		#	"name" : sprite_name,
		#	"images" : images,
		#	"center" : null
		#})
	loaded_metas[asset] = sprites
	return sprites

func simple_sprite(asset, specific_sprite='', lazy=0):
	# gets the first subimage of the first sprite of a meta sprite
	# optionally get the first subimage of a specific sprite
	
	#var cache_name = asset + '/' + specific_sprite

	if lazy:
		asset = lazy_find(asset)
	#if cache_name in loaded_atlases.keys():
	#	return loaded_atlases[asset]
	
	var tex = sprite_sheet(asset.replace(".meta", ".png"), lazy)

	var buffer = get(asset)
	var sprite : Sprite = Sprite.new()
	var position = 0x10 + 0x04 + 0x04
	
	while position < len(buffer):
		# parse sprite name
		var sprite_name_l = buffer[position]
		position += 1
		var sprite_name = buffer.subarray(position, position+sprite_name_l-1).get_string_from_ascii()
		#sprites.add_animation(sprite_name)
		
		# parse sub image count
		position += sprite_name_l
		var image_count = byte_array_to_int(buffer.subarray(position, position+4))
		position += 4
		
		# skip sprite if not the specified sprite
		if specific_sprite != '' and sprite_name != specific_sprite:
			position += 36 * image_count
			continue
		
		var ref_region = null
		if image_count > 0:
			position += 4
			var img = AtlasTexture.new()
			ref_region = Rect2(
				byte_array_to_int(buffer.subarray(position+8, position+8+4)),
				byte_array_to_int(buffer.subarray(position+12, position+12+4)),
				byte_array_to_int(buffer.subarray(position, position+4)),
				byte_array_to_int(buffer.subarray(position+4, position+4+4))
			);
			img.region = ref_region
			img.atlas = tex
			position += 32
			sprite.texture = img
		if ref_region != null and sprite_name != "" and sprite_name in sprite_centers:
			for i in range(0, len(sprite_centers), 3):
				if sprite_centers[i] == sprite_name:
					sprite.offset = ref_region.size/2 - Vector2(
						int(sprite_centers[i+1]),
						int(sprite_centers[i+2])
					)
		else:
			sprite.offset = Vector2(0, 0)
		return sprite
	return sprite
