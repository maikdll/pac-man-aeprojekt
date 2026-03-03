extends Control

@onready var container = $HBoxContainer

# Die Variablen wurden an die echten Original-Namen angepasst:
@export var cherry: Texture2D     
@export var strawberry: Texture2D
@export var orange: Texture2D
@export var apple: Texture2D      
@export var melon: Texture2D
@export var galaxian: Texture2D  
@export var bell: Texture2D      
@export var key: Texture2D       

func _ready():
	update_fruitbar()

func update_fruitbar():
	# 1. Erstmal alle alten Symbole löschen
	for child in container.get_children():
		child.queue_free()

	# 2. Die Magie für die 3 Items:
	var start_level = max(1, Global.level - 2)
	var end_level = Global.level

	# 3. Die neuen Symbole für die letzten 3 Level laden
	for i in range(start_level, end_level + 1):
		var tex = get_texture_for_level(i)
		if tex != null: # Kleine Sicherung, falls mal ein Bild fehlt
			add_icon(tex)

func get_texture_for_level(lvl: int) -> Texture2D:
	if lvl == 1:
		return cherry
	elif lvl == 2:
		return strawberry
	elif lvl == 3 or lvl == 4:
		return orange
	elif lvl == 5 or lvl == 6:
		return apple
	elif lvl == 7 or lvl == 8:
		return melon
	elif lvl == 9 or lvl == 10:
		return galaxian
	elif lvl == 11 or lvl == 12:
		return bell
	else:
		return key # Level 13 und alles danach ist der Schlüssel

func add_icon(texture):
	var new_icon = TextureRect.new()
	new_icon.texture = texture
	new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_icon.custom_minimum_size = Vector2(44, 44)
	new_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(new_icon)
