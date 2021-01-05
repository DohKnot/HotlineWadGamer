extends Node

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
