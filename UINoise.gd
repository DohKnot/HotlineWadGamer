extends NinePatchRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var f = "Atlases/Sprites/Interface/TitleScreen/sprNoise.png"
	texture = GameManager.env_wad.sprite_sheet(f)
	texture.set_flags(Texture.FLAG_REPEAT)
	region_rect.size = texture.get_size()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	region_rect.position = Vector2(randi() % int(texture.get_size().x), randi() % int(texture.get_size().y))
