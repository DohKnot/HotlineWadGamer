extends KinematicBody2D

# Internal
var _wad = null
# leg frame index
var _legindex = 0
var _bodyindex = 0

# Nodes
onready var sprite_dummy = $AnimatedSprite
onready var legs_dummy = $Legs

# Player Variables
export var myspeed = 3
export var weapon = GameManager.Weapon.UNARMED
var myxspeed = 0
var myyspeed = 0
# attack duration
var reload = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_wad = GameManager.player_wad
#	sprite_dummy.frames = _wad.meta_sprite("Atlases/Player_Jacket.meta")
#	sprite_dummy.play("sprJacketWalkUnarmed")
#	sprite_dummy.speed_scale = 0
#	legs_dummy.frames = _wad.meta_sprite("Atlases/Enemy_Gang.meta")
#	legs_dummy.play("sprEGangLegs")
#	legs_dummy.speed_scale = 0
	init_player("sprZebraWalkUnarmed")

func init_player(spr_name):
	var d = {
	#	token				legs				faction
		"Jacket":	["Enemy_Gang",		"sprEGang",		"Player_Jacket"],
		"Biker":		["Player_Biker",		"sprPolice",		"Player_Biker"],
		"Bear":		["Player_Bear",		"sprEGang",		"Player_Bear"],
		"Zebra":		["Player_Zebra",		"sprZebra",		"Player_Zebra"],
		"Tiger":		["Player_Tiger",		"sprTiger",		"Player_Tiger"],
		"Swan":		["Player_Swan",		"sprSwan",		"Player_Swan"],
		"Nicke":		["Player_Nicke",		"sprSoldier",		"Player_Nicke"],
		"Cop":		["Player_Cop",		"sprPrisoner",	"Player_Cop"],
		"Writer":	["Player_Writer",		"sprWriter",		"Player_Writer"],
		"RatPrison":	["Player_Rat",		"sprRatPrison",	"Player_Rat"],
		"RatGuard":	["Enemy_Guards",		"sprGuard",		"Player_Rat"],
		"Rat":		["Player_Rat",		"sprRat",		"Player_Rat"],
		"Pig":		["Player_PigButcher",	"sprPig",		"Player_PigButcher"],
		"Hammer":	["Player_Hammarin",	"sprHammer",		"Player_Hammarin"],
		"Son":		["Enemy_Mafia",		"sprSon",		"Player_Son"],
		"Henchman":	["Enemy_Mafia",		"sprEMafia",		"Player_Henchman"],
	}
	
	var token = "Zebra"
	var body_faction = d[token][2]
	var legs_faction = d[token][0]
	var legs_name = d[token][1]
	for i in d.keys():
		if i in spr_name:
			body_faction = d[i][2]
			legs_faction = d[i][0]
			legs_name = d[i][1]
			break
	
	sprite_dummy.frames = _wad.meta_sprite("Atlases/" + body_faction + ".meta")
	sprite_dummy.play(spr_name)
	sprite_dummy.stop()
	sprite_dummy.speed_scale = 0
	legs_dummy.frames = _wad.meta_sprite("Atlases/" + legs_faction + ".meta")
	legs_dummy.play(legs_name + "Legs")
	legs_dummy.stop()
	legs_dummy.speed_scale = 0

func _process(delta):
	if Input.is_action_just_pressed("restart"): get_tree().reload_current_scene()
	player_move(delta)
	sprite_dummy.rotation = $Cursor.position.angle()
	if Input.is_action_pressed("attack"):
		attack()
	var r  = 0.13 + 0.02 * randf()
	$Light.scale = Vector2(r, r)
	update()

func _input(event):
	if event.is_action_pressed("attack"):
		attack()

func _draw():
	for c in get_children():
		if c is AnimatedSprite:
			var sprite_tex = c.frames.get_frame(c.animation, c.frame)
			var v = Vector2(-1 if c.flip_h else 1,   -1 if c.flip_v else 1)
			draw_set_transform(Vector2.ZERO, v.y * c.rotation, v)
			draw_texture(sprite_tex, c.position + v*Vector2(1,1).rotated(-c.rotation) - sprite_tex.get_size()/2 + c.offset, Color(0,0,0,0.5))

func player_move(delta):
	var normalized_delta = 60 * delta
	var d = 0.5 * normalized_delta
	var x = position.x;
	var y = position.y;
	
	var up = Input.is_action_pressed("up")
	var down = Input.is_action_pressed("down")
	var left = Input.is_action_pressed("left")
	var right = Input.is_action_pressed("right")

	# Default Controls.
	if (left):
		#if (myxspeed > -(myspeed)) { myxspeed -= 0.5f; } else { myxspeed = -(myspeed); }
		#myxspeed = myxspeed - 0.5 if (myxspeed > -myspeed) else -(myspeed)
		myxspeed = max(myxspeed - d, -myspeed)
	if (right):
		#if (myxspeed < (myspeed)) { myxspeed += 0.5f; } else { myxspeed = (myspeed); }
		#myxspeed = myxspeed + 0.5 if (myxspeed < (myspeed)) else myspeed
		myxspeed = min(myxspeed + d, myspeed)
	if (up):
		#if (myyspeed > -(myspeed)) { myyspeed -= 0.5f; } else { myyspeed = -(myspeed); }
		myyspeed = max(myyspeed - d, -myspeed)
	if (down):
		#if (myyspeed < (myspeed)) { myyspeed += 0.5f; } else { myyspeed = (myspeed); }
		myyspeed = min(myyspeed + d, myspeed)



	# Adresses conflicts in directions.
	# Doesn't do that it actually just decelerates the player when no buttons are pressed... very jank
	if (!right && !left):
		#if (myxspeed > 0f) { myxspeed -= 0.5f; } else { if (myxspeed < -0.5f) { myxspeed += 0.5f; } else { myxspeed = 0f; } }
		if (myxspeed > 0):
			myxspeed -= d
		else:
			if (myxspeed < -d):
				myxspeed += d
			else:
				myxspeed = 0

	if (!up && !down):
		#if (myyspeed > 0f) { myyspeed -= 0.5f; } else { if (myyspeed < -0.5f) { myyspeed += 0.5f; } else { myyspeed = 0f; } }
		if (myyspeed > 0):
			myyspeed -= d
		else:
			if (myyspeed < -d):
				myyspeed += d
			else:
				myyspeed = 0


	while ((abs(myxspeed) + abs(myyspeed)) > myspeed + 2):
		myxspeed *= 0.98
		myyspeed *= 0.98

	# Leg index.
	if (abs(myxspeed) == 0 && abs(myyspeed) == 0):
		legs_dummy.frame = 0
		_legindex = 0
	else:
		var temp = min(myspeed, abs(myxspeed) + abs(myyspeed)) * normalized_delta
		_legindex += temp * 0.1 #* factor
		legs_dummy.frame = int(_legindex) % legs_dummy.frames.get_frame_count(legs_dummy.animation)
		# Is the player moving? if yes, increase the image_index of the legs' sprites.
		if "Walk" in sprite_dummy.animation:
			_bodyindex += temp * 0.05
			sprite_dummy.frame = int(_bodyindex) % sprite_dummy.frames.get_frame_count(sprite_dummy.animation)
	legs_dummy.rotation = Vector2(myxspeed, myyspeed).angle()
	
	var _myxspeed = myxspeed
	var _myyspeed = myyspeed
	var _myspeed = myspeed
	myxspeed *= normalized_delta
	myyspeed *= normalized_delta
	myspeed *= normalized_delta
	myxspeed = float(int(myxspeed*100)) / 100
	myyspeed = float(int(myyspeed*100)) / 100
	myspeed = float(int(myspeed*100)) / 100
	#if abs(myxspeed) < 0.1:
	#	myxspeed = 0
	#if abs(myyspeed) < 0.1:
	#	myyspeed = 0
	
	var jd = 8
	if (abs(myxspeed) > 0):
		if (!place_free(x + myxspeed, y)):
			x += myxspeed
		elif (myyspeed == 0):
			if (!place_free(x + myxspeed, y - jd)):
				y -= myspeed
			elif (!place_free(x + myxspeed, y + jd)):
				y += myspeed
			else:
				#move_contact_solid(90 - sign(myxspeed) * 90, abs(myxspeed));
				_myxspeed = 0

	if (abs(myyspeed) > 0):
		if (!place_free(x, y + myyspeed)):
			y += myyspeed 
		elif (myxspeed == 0):
			if (!place_free(x - jd, y + myyspeed)):
				x -= myspeed
			elif (!place_free(x + jd, y + myyspeed)):
				x += myspeed
			else:
				_myyspeed = 0
	
	#move_and_collide(Vector2(myxspeed * 60, myyspeed * 60))
	
	$Label.text = str(myxspeed)
	$Label2.text = str(myyspeed)
	myxspeed = _myxspeed
	myyspeed = _myyspeed
	myspeed = _myspeed
	position = Vector2(x, y)
	#move_and_slide()

func place_free(x,y):
	var v = Vector2(x,y) - position
	#var c = move_and_collide(Vector2(1000 * (v.x/1000), 1000 * (v.y/1000)), true, true, true)
	#var c = move_and_collide(v, true, true, true)
	var c = test_move(transform, v)
	return c
	
	#print(Vector2(x,y) - position)
	#return test_move(transform, Vector2(x,y) - position)

func attack():
	if "Walk" in sprite_dummy.animation:
		if "Unarmed" in sprite_dummy.animation:
			sprite_dummy.play(sprite_dummy.animation.replace("WalkUnarmed", "AttackPunch"))
			sprite_dummy.speed_scale = 0.35
		else:
			sprite_dummy.play(sprite_dummy.animation.replace("Walk", "Attack"))
			sprite_dummy.speed_scale = 0.35

func _on_AnimatedSprite_animation_finished():
	if GameManager.weapon_type(weapon) == GameManager.Weapon_t.MELEE or weapon == GameManager.Weapon.UNARMED:
		sprite_dummy.flip_v = !sprite_dummy.flip_v
	if "Attack" in sprite_dummy.animation:
		if "Punch" in sprite_dummy.animation:
			sprite_dummy.play(sprite_dummy.animation.replace("AttackPunch", "WalkUnarmed"))
			sprite_dummy.stop()
			sprite_dummy.frame = 0
		else:
			sprite_dummy.play(sprite_dummy.animation.replace("Attack", "Walk"))
			sprite_dummy.stop()
			sprite_dummy.frame = 0
