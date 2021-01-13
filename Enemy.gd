extends Node2D

enum Enemy_t {
	RANDOM,
	PATROL,
	DOG_PATROL,
	STATIONARY
}

export(NodePath) var Legs
export(NodePath) var Body
export(NodePath) var KBody

export var CHECKRELOAD = 30
export var ALERTWAIT = 16
export var TURNSPEED = 10
export var WALKSPEED = 1
export var PATHSPEED = 2
export var RUNSPEED = 3
export var RUNSPEED_DOG = 5
export var VIEW_DIST = 280


var speed = 0
var direction = 0

var weapon = GameManager.Weapon.M16
var behaviour = Enemy_t.PATROL

var players = []
var player_focused = null

var checkReload = 0
var alertWait = 0
var state = 0
var random_timer = 0

var delta_time = 0

func _ready():
	
	Body = get_node(Body)
	Legs = get_node(Legs)
	KBody = get_node(KBody)
	
	var _wad = GameManager.player_wad
	
	Body.frames = _wad.meta_sprite("Atlases/Enemy_Mafia.meta")
	var weapon_name = GameManager.Weapon.keys()[weapon]
	Body.play("sprEMafiaWalk" + weapon_name.capitalize().replace(' ',''))
	Body.speed_scale = 0
	
	Legs.frames = Body.frames
	Legs.play("sprEMafiaLegs")
	Legs.speed_scale = 0
	players = get_tree().get_nodes_in_group("Player")


func _physics_process(delta):
	delta_time = delta * 60
	match state:
		0: state0()
		1: state1()
		2: state2()
		3: state3()
	var v = speed * Vector2(cos(deg2rad(direction)), sin(deg2rad(direction))) * delta_time
	KBody.position += v
	Body.rotation_degrees = direction
	$KBody/Label.text = str(state)
	$KBody/Label2.text = str(checkReload)
	$KBody/Label3.text = str(alertWait)
func _process(delta):
	update()
func _draw():
	#for c in get_children():
	#	if c is AnimatedSprite:
	var c = Legs
	var sprite_tex = c.frames.get_frame(c.animation, c.frame)
	#draw_set_transform(c.global_position - position, c.rotation, Vector2.ONE)
	#draw_texture(sprite_tex, Vector2(1,1).rotated(-c.rotation) - sprite_tex.get_size()/2 + c.offset, Color(0,0,0,0.5))
	c = Body
	sprite_tex = c.frames.get_frame(c.animation, c.frame)
	draw_set_transform(c.global_position - position, c.rotation, Vector2.ONE)
	draw_texture(sprite_tex, Vector2(1,1).rotated(-c.rotation) - sprite_tex.get_size()/2 + c.offset, Color(0,0,0,0.5))

func init_enemy(spr_name):
	#weapon = _weapon
	
	# get weapon
	for w in GameManager.Weapon.keys():
		if w.capitalize().replace(' ','') in spr_name:
			weapon = GameManager.Weapon[w]
			break

	var d = {
	#	Faction		Normal legs		Fat legs
		"Mafia":		["sprEMafia",		"sprEMafiaFat"],
		"Gang":		["sprEGang",		"sprEGangFat"],
		"Police":	["sprPolice",		"sprFatPolice"],
		"Soldier":	["sprSoldier",	"sprFatSoldier"],
		"Prisoner":	["sprPrisoner",	"sprPrisonerFat"],
		"Colombian":	["sprColombian",	"sprEMafiaFat"],
		"Guard":		["sprGuard"],
		"Dog":		[],
#		"PigButcher":["sprVictim"],
	}
	var _wad = GameManager.player_wad
	
	var fat = "Fat" in spr_name
	var dog = "Dog" in spr_name
	
	var faction_name = "Mafia"
	var legs_name = "sprEMafia"
	for i in ["Gang", "Police", "Soldier", "Prisoner", "Colombian", "Guard", "Dog"]:
		if i in spr_name:
			faction_name = i
			if !dog:
				legs_name = d[i][0]
				if fat:
					legs_name = d[i][1]
			break
	# edge cases
	if faction_name == "Colombian" and fat:
		faction_name = "Mafia"
	Body.frames = _wad.meta_sprite("Atlases/Enemy_" + faction_name + ".meta")
	Body.play(spr_name)
	Body.speed_scale = 0
	
	if !dog:
		Legs.frames = Body.frames
		Legs.play(legs_name + "Legs")
		Legs.speed_scale = 0
	else:
		Legs.hide()
	players = get_tree().get_nodes_in_group("Player")

#func weapon_to_anim(_weapon):
#	if weapon_type(_weapon) == GameManager.Weapon.FATSO:
#		return faction + "FatWalk"
#	var weapon_name = GameManager.Weapon.keys()[weapon]
#	return faction + "Walk" + weapon_name.capitalize().replace(' ','')
#func anim_to_weapon(sprite_name):
#	sprite_name = sprite_name.replace("Walk", '')
#	sprite_name = sprite_name.replace("Attack", '')
#	var ret = sprite_name.substr(len(faction), 999).to_upper()
#	return GameManager.Weapon[ret]
#func anim_to_faction(sprite_name):
#	for i in ["FatWalk", "Walk", "Attack"]:
#		if i in sprite_name:
#			return sprite_name.substr(0, sprite_name.find(i))
#	assert(true == false)

func weapon_type(weapon):
	return GameManager.weapon_type(weapon)

func switch_state(new_state):
	#match new_state:
	#	
	state = new_state

func state0():
	# neutral behaviors
	match (behaviour):
		Enemy_t.RANDOM:
			random_timer -= 1 * delta_time
			if (random_timer <= 0) or speed > 2:
				direction = randi() % 360
				speed = randi() % 2
				random_timer = 60 + (randi() % 61)
			var v = Vector2(speed * cos(deg2rad(direction)) * delta_time, speed * sin(deg2rad(direction)) * delta_time)
			var c = KBody.move_and_collide(v, true, true, true)
			if c:
				v = v.bounce(c.normal)
				direction = rad2deg(v.angle())
		Enemy_t.PATROL:
			speed = WALKSPEED
			#direction = round(direction/10)*10
			var v = 8 * Vector2(cos(deg2rad(direction)) * delta_time, sin(deg2rad(direction)) * delta_time)
			var c = KBody.move_and_collide(v, true, true, true)
			if c:
				direction -= 10 * delta_time
			else:
				var dif = fmod(direction, 90)
				if abs(dif) > 10 * delta_time:
					direction -= 10 * delta_time
				else:
					direction -= dif
			#if !place_free(x+lengthdir_x(8,direction),y+lengthdir_y(direction))
			# TODO: turn on collisions and stuff
		Enemy_t.DOG_PATROL:
			speed = WALKSPEED * delta_time
			# TODO: turn on corners and stuff
		Enemy_t.STATIONARY:
			speed = 0
	
	# main los check timer
	if(checkReload <= 0):
		# 0 no los, 1 direct, or 2 indirect
		var los = check_los()
		if (los == 1): alertWait = ALERTWAIT
		if (los == 2): switch_state(2)
		checkReload = CHECKRELOAD

	# reaction delay timer
	if (alertWait <= 0 and alertWait != -1):
		var los = check_los()
		if (los == 1): switch_state(1)
		if (los == 2): switch_state(2)
		alertWait = -1

	# decrement timers
	if (checkReload > 0 && alertWait == -1): checkReload -= 1 * delta_time
	if (alertWait > -1): alertWait -= 1 * delta_time

func state1():
	if player_focused == null:
		switch_state(0)
	# TODO: add blunt (unarmed) edge case
	var d = 12*12
	match (weapon_type(weapon)):
		GameManager.Weapon_t.GUN:
			d = 80*80
			continue
		GameManager.Weapon_t.GUN,\
		GameManager.Weapon_t.MELEE,\
		GameManager.Weapon_t.FATSO:
			if KBody.global_position.distance_squared_to(player_focused.position) > d:
				speed = min(speed + 0.5 * delta_time, RUNSPEED)
			else:
				speed = max(speed - 0.25 * delta_time, 0)
			#direction = rad2deg(position.angle_to_point(player_focused.position)) - 180
			direction = hm1_rotate(direction, rad2deg(player_focused.position.angle_to_point(KBody.global_position)), TURNSPEED * delta_time)
		GameManager.Weapon_t.DOG:
			speed = max(speed + 0.25 * delta_time, RUNSPEED_DOG * delta_time)
	var los = check_los() # 0 none, 1 direct, 2 indirect
	#if (los == 1): switch_state(1)
	if (los == 0): switch_state(3)

func state2():
	if player_focused == null:
		switch_state(0)
	if(weapon_type(weapon) == GameManager.Weapon_t.GUN):
		var dist_to_focused_player = VIEW_DIST + 1; # implement later idk
		if (dist_to_focused_player > VIEW_DIST):
			switch_state(3)
			return
		# TODO: Shoot function
		#enemy_shoot()
		check_los()
	
	switch_state(3)

func state3():
	switch_state(0)
	pass

func check_los():
	# 0 none, 1 direct, 2 indirect
	var space_state = get_world_2d().direct_space_state
	var los = 0
	if player_focused == null:
		for p in players:
			var dist = KBody.global_position.distance_squared_to(p.position)
			var angl = rad2deg(KBody.global_position.angle_to_point(p.position))
			var vd = Vector2(cos(deg2rad(angl+90)), sin(deg2rad(angl+90))) * 8
			var result1 = space_state.intersect_ray(KBody.global_position + vd, p.position + vd, [KBody], 0b00000000000000000101)
			vd = Vector2(cos(deg2rad(angl-90)), sin(deg2rad(angl-90))) * 8
			var result2 = space_state.intersect_ray(KBody.global_position + vd, p.position + vd, [KBody], 0b00000000000000000101)
			#if KBody.global_position.distance_squared_to(p.position) < 100*100:
			if result1 and result2 and "PlayerPlayer" == result1.collider.name+result2.collider.name:
				player_focused = p
				los = 1
				return los
	else:
		var p = player_focused
		var dist = KBody.global_position.distance_squared_to(p.position)
		var angl = rad2deg(KBody.global_position.angle_to_point(p.position))
		var result = space_state.intersect_ray(KBody.global_position, p.position, [KBody], 0b00000000000000000101)
		#if KBody.global_position.distance_squared_to(p.position) < 100*100:
		if result and "Player" == result.collider.name:
			player_focused = p
			los = 1
			return los
	if los == 0: player_focused = null
	return los

func place_free(v):
	return KBody.test_move(transform, v)

func hm1_rotate(tur_dir, destdir, turnspeed):
	if (tur_dir > 359): tur_dir = 0
	if (tur_dir < 0): tur_dir = 359
	var dir = destdir - tur_dir
	if (dir > 180): dir = -(360-dir)
	if (dir < -180): dir = 360+dir

	if(dir <= turnspeed):
		tur_dir += dir
	else:
		tur_dir += sign(dir) * turnspeed
	return tur_dir

