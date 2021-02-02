extends Sprite

class_name SpriteShadow

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var shadow_distance = 3
var shadow_intensity = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _draw():
	
	#print("drawTest.is_visible() = ", drawTest.is_visible())
	#drawTest.set_z(1)
	#drawTest.draw_line(Vector2(0,600), Vector2(1024, 0), Color(0, 255, 0), 1)
	#$Node2D.draw_set_transform(global_position - position, rotation, Vector2.ONE)
	#$Node2D.draw_texture(texture, shadow_distance * Vector2(1,1).rotated(-rotation) - texture.get_size()/2 + offset, Color(0,0,0, shadow_intensity))
	$Shadow.texture = texture
	$Shadow.offset = offset
	$Shadow.position = shadow_distance * Vector2(1,1).rotated(-rotation)
	$Shadow.modulate = Color(0,0,0, shadow_intensity)
