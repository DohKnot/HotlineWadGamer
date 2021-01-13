extends AnimatedSprite

class_name WadSprite

func _process(delta):
	#var fs : WadFrames = frames
	offset = frames.centers[animation]
