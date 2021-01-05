extends AnimatedSprite

class_name WadSprite

func _draw():
	#var fs : WadFrames = frames
	offset = frames.centers[animation]
