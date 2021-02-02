extends Sprite


export(float) var r
export(float) var dr


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var d = 2*(r + randf()*dr) / texture.get_size().x
	scale = Vector2(d,d)
