extends Node

# Gameplay stuff
enum Weapon_t {
	BLUNT,
	GUN,
	MELEE,
	DOG,
	FAT
}
enum Weapon {
	UNARMED,
	M16,
	KALASHNIKOV,
	SHOTGUN,
	DOUBLE_BARREL,
	SILENCER,
	_9MM,
	MAGNUM,
	UZI,
	CLUB,
	BAT,
	PIPE,
	KNIFE,
	DOG,
	FAT,
}

var gun_stats = {
#	Weapon : [mzl_dst, mzl_ang, sprd, rld, nbullets, blt_sped_sprd]
	Weapon.M16 :			[16, -7, 6, 2, 1, 0],
	Weapon.KALASHNIKOV :	[16, -7, 6, 3, 1, 0],
	Weapon.SHOTGUN :		[16, -7, 12, 30, 8, 4],
	Weapon.DOUBLE_BARREL :	[16, -7, 20, 8, 16, 6],
	Weapon.SILENCER :		[20, -7, 6, 10, 1, 0],
	Weapon._9MM :			[20, -7, 6, 10, 1, 0],
	Weapon.MAGNUM :			[20, -7, 0, 10, 1, 0],
	Weapon.UZI :			[20, -7, 10, 1, 1, 0],
}

# Gameplay stuff
var bullet_prefab = preload("res://Bullet.tscn")
var weapon_prefab = preload("res://WeaponDrop.tscn")
var object_prefab = preload("res://HMObject.tscn")
var shadow_prefab = preload("res://HMShadowSprite.tscn")
var hm2lvl_prefab = preload("res://HM2CustomLevel.tscn")

var lvl_cache = {}

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

func _input(event):
	if event.is_action_pressed("restart"):
		for l in get_tree().get_nodes_in_group("Level"):
			var nl = hm2lvl_prefab.instance()
			l.get_parent().add_child(nl)
			l.queue_free()
			get_tree().get_nodes_in_group("Player")[0].position = Vector2(30,30)
	if event.is_action_pressed("hard_restart"): get_tree().reload_current_scene()

func get_weapon_name(weapon):
	return Weapon.keys()[weapon].capitalize().replace(' ','')

func weapon_type(weapon):
	match (weapon):
		GameManager.Weapon.SILENCER,\
		GameManager.Weapon.M16,\
		GameManager.Weapon.KALASHNIKOV,\
		GameManager.Weapon.SHOTGUN,\
		GameManager.Weapon.DOUBLE_BARREL,\
		GameManager.Weapon._9MM,\
		GameManager.Weapon.SILENCER,\
		GameManager.Weapon.MAGNUM,\
		GameManager.Weapon.UZI:
			return GameManager.Weapon_t.GUN
		GameManager.Weapon.BAT,\
		GameManager.Weapon.CLUB,\
		GameManager.Weapon.PIPE,\
		GameManager.Weapon.KNIFE:
			return GameManager.Weapon_t.MELEE
		GameManager.Weapon.FAT: return GameManager.Weapon_t.FAT
		GameManager.Weapon.DOG: return GameManager.Weapon_t.DOG
	return GameManager.Weapon_t.BLUNT
