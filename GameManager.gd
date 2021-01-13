extends Node

# Gameplay stuff
enum Weapon_t {
	BLUNT,
	GUN,
	MELEE,
	DOG,
	FATSO
}
enum Weapon {
	UNARMED,
	M16,
	KALASHNIKOV,
	SHOTGUN,
	DOUBLEBARREL,
	SILENCER,
	_9MM,
	CLUB,
	BAT,
	PIPE,
	KNIFE,
	DOG,
	FAT,
}

# Resource stuff
var player_wad = null
var env_wad = null
var sprite_key_table = null
var object_table = {}

func _init():
	ResourceManager.open_wad("res://hlm2_data_desktop.wad")
	player_wad = ResourceManager.fallback_wad
	env_wad = ResourceManager.fallback_wad
	
	
	# sprite name table
	var data_file = File.new()
	if data_file.open("res://sprite_key_table.json", File.READ) != OK:
		print("error opening sprite_key_table")
		return 1
	var data_text = data_file.get_as_text()
	data_file.close()
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		print("error parsing sprite_key_table")
		return 1
	sprite_key_table = data_parse.result

	# object data table
	var obj_data_file = File.new()
	obj_data_file.open("res://objects.csv", File.READ)
	obj_data_file.get_line()
	var l = obj_data_file.get_line().split(',')
	while !obj_data_file.eof_reached():
		object_table[int(l[0])] = {
			'name' : l[1],
			'spritekey' : int(l[2]),
			'parent' : int(l[4])
		}
		l = obj_data_file.get_line().split(',')
	#print(object_table[])

func weapon_type(weapon):
	match (weapon):
		GameManager.Weapon.SILENCER,\
		GameManager.Weapon.M16,\
		GameManager.Weapon.KALASHNIKOV,\
		GameManager.Weapon.SHOTGUN,\
		GameManager.Weapon.DOUBLEBARREL:
			return GameManager.Weapon_t.GUN
		GameManager.Weapon.BAT,\
		GameManager.Weapon.CLUB,\
		GameManager.Weapon.PIPE,\
		GameManager.Weapon.KNIFE:
			return GameManager.Weapon_t.MELEE
		GameManager.Weapon.FAT: return GameManager.Weapon_t.FATSO
		GameManager.Weapon.DOG: return GameManager.Weapon_t.DOG
	return GameManager.Weapon_t.BLUNT
