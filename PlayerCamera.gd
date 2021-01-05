extends Camera2D

onready var player = get_parent().get_node("Player")
onready var l_pos = position

func _ready():
	pass

func _process(delta):
	var pos = (player.global_position + player.get_node("Cursor").global_position) / 2
	l_pos += (pos - l_pos) * delta * 60 * 0.1
	#position = Vector2((1/snap) * float((int(position.x / (10/snap)) % snap)), (1/snap) * float((int(position.y / (10/snap)) % snap)))
	position = Vector2(stepify(l_pos.x, 0.25), stepify(l_pos.y, 0.25))
