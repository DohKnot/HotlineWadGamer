extends Node2D

export(NodePath) var sprite
export(NodePath) var KBody

var speed = 0
var calibre = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite = get_node(sprite)
	KBody = get_node(KBody)
	
	var _wad = GameManager.player_wad
	
	var l = _wad.single_frame("Atlases/Effects.meta", "sprBullet")
	sprite.texture = l[0]
	sprite.offset = l[1]

func _process(delta):
	modulate = Color.white.linear_interpolate(Color.yellow, randf())
	$Smoothing2D/SimpleLight.modulate.a = calibre

func _physics_process(delta):
	var v = speed * Vector2(cos(rotation), sin(rotation)) * 60 * delta
	var c = KBody.move_and_collide(v)
	if c:
		if c.collider.get_parent().is_in_group("Enemy"):
			c.collider.get_parent().die()
		queue_free()


func _on_Timer_timeout():
	queue_free()
