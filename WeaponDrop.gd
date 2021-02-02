extends Node2D
# WEAPON DORP

export(NodePath) var sprite
export(NodePath) var KBody

var weapon_id = 0

var speed = 0
var direction = 0
var friction = 0.25

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = get_node(sprite)
	KBody = get_node(KBody)
	
	var _wad = GameManager.player_wad
	
	var l = _wad.single_frame("Atlases/Weapons.meta", "sprDisarmedGuns", randi()%7)
	sprite.texture = l[0]
	sprite.offset = l[1]

func _process(delta):
	sprite.rotate(speed * delta * 4)

func _physics_process(delta):
	var v = speed * Vector2(cos(direction), sin(direction)) * 60 * delta
	var c = KBody.move_and_collide(v)
	if c:
		#if c.collider.get_parent().is_in_group("Enemy"):
		#	c.collider.get_parent().die()
		direction = v.bounce(c.normal).angle()
		speed *= 0.7
	speed = max(0, speed - friction * 60 * delta)


func _on_Timer_timeout():
	queue_free()
