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
var myxspeed = 0
var myyspeed = 0
# attack duration
var reload = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_wad = GameManager.player_wad
	sprite_dummy.frames = _wad.meta_sprite("Atlases/Player_Jacket.meta")
	sprite_dummy.play("sprJacketWalkUnarmed")
	sprite_dummy.speed_scale = 0
	legs_dummy.frames = _wad.meta_sprite("Atlases/Enemy_Gang.meta")
	legs_dummy.play("sprEGangLegs")
	legs_dummy.speed_scale = 0

func _process(delta):
	player_move(delta)
	sprite_dummy.rotation = $Cursor.position.angle()
	update()

func _draw():
	for c in get_children():
		if c is AnimatedSprite:
			var sprite_tex = c.frames.get_frame(c.animation, c.frame)
			draw_set_transform(Vector2.ZERO, c.rotation, Vector2.ONE)
			draw_texture(sprite_tex, c.position + Vector2(1,1).rotated(-c.rotation) - sprite_tex.get_size()/2 + c.offset, Color(0,0,0,0.5))

func player_move(delta):
	var normalized_delta = 60 * delta
	var d = 0.5 * 60 * delta
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
	var c = move_and_collide(v, true, true, true)
	#if c:
	#	return false
	#return true
	return c
	
	#print(Vector2(x,y) - position)
	#return test_move(transform, Vector2(x,y) - position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
