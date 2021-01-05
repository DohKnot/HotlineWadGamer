extends Node

# dictionary of wads currently in memory
# file_path : Wad
# wads[file_path] = Wad_Object
var wads = {}
var fallback_wad = null


func open_wad(file_path):
	if file_path in wads:
		return
		
	var wad = Wad.new()
	wad.open(file_path, File.READ)
	wad.parse_header()
	
	wads[file_path] = wad
	if fallback_wad == null:
		fallback_wad = wad
