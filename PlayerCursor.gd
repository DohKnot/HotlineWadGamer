extends WadSprite


# Declare member variables here. Examples:
var _wad = null


# Called when the node enters the scene tree for the first time.
func _ready():
	_wad = GameManager.player_wad
	frames = _wad.meta_sprite("Atlases/Sprites/Interface/Editor/sprCursor.meta")
	play("sprCursor")
	speed_scale = 0.25

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size/2
	position *= 2
