extends Node2D

# HMOBJECT

export(NodePath) var sprite
export(NodePath) var KBody

var speed = 0.00
var direction = 0.00
var friction = 0.00

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = get_node(sprite)
	KBody = get_node(KBody)
	
	var _wad = GameManager.env_wad
	
	var l = _wad.single_frame("Atlases/Weapons.meta", "sprDisarmedGuns", randi()%7)
	sprite.texture = l[0]
	sprite.offset = l[1]

func _process(delta):
	var v = speed * Vector2(cos(direction), sin(direction)) * 60 * delta
	#var c = KBody.move_and_collide(v)
	KBody.position += v
	speed = max(0, speed - friction * 60 * delta)
