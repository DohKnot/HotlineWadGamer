extends Sprite

func _process(delta):
	#rect_position = 2
	var r = 2*(240 + randf()*24 + 24) / texture.get_size().x
	scale = Vector2(r,r)
	material.set_shader_param("black", Color.navyblue.linear_interpolate(Color.aqua, 0.25+0.25*randf()))
