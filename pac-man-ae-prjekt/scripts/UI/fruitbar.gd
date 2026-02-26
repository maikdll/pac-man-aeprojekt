extends Control

@onready var container = $HBoxContainer

@export var cherry: Texture2D    
@export var strawberry: Texture2D
@export var peach: Texture2D    
@export var apple: Texture2D     
@export var grape: Texture2D    
@export var galaxian: Texture2D 
@export var bell: Texture2D     
@export var key: Texture2D       

func _ready():
	print("Global Level ist: ", Global.level)
	update_fruitbar()

func update_fruitbar():
	for child in container.get_children():
		child.queue_free()

	var start_level = max(1, Global.level - 6)
	var end_level = Global.level

	for i in range(start_level, end_level + 1):
		var tex = get_texture_for_level(i)
		add_icon(tex)

func get_texture_for_level(lvl: int) -> Texture2D:
	if lvl == 1:
		return cherry
	elif lvl == 2:
		return strawberry
	elif lvl == 3 or lvl == 4:
		return peach
	elif lvl == 5 or lvl == 6:
		return apple
	elif lvl == 7 or lvl == 8:
		return grape
	elif lvl == 9 or lvl == 10:
		return galaxian
	elif lvl == 11 or lvl == 12:
		return bell
	else:
		return key

func add_icon(texture):
	var new_icon = TextureRect.new()
	new_icon.texture = texture
	new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_icon.custom_minimum_size = Vector2(500, 500)
	new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(new_icon)
