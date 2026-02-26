extends CharacterBody2D

# Geschwindigkeit anpassen (etwas langsamer als Pacman ist fair)
@export var speed = 100

# Start-Richtung (z.B. nach rechts)
var current_dir = Vector2.RIGHT

func _ready():
	# Beim Start direkt eine zufällige Richtung wählen
	choose_new_direction()

func _physics_process(delta):
	# Bewegung setzen
	velocity = current_dir * speed
	
	# move_and_slide bewegt den Geist und handhabt Kollisionen mit der TileMap
	move_and_slide()
	
	# Die magische Funktion von Godot: 
	# Wenn wir eine Wand (TileMap) berühren, geben wir true zurück
	if is_on_wall():
		choose_new_direction()

func choose_new_direction():
	# Alle möglichen Richtungen definieren
	var directions = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	
	# Optional: Verhindern, dass er sofort umdreht (ping-pong vermeidung)
	# Wenn er nach rechts ging, soll er nicht sofort nach links gehen, außer er muss.
	# (Kannst du für den Anfang auch weglassen, macht es aber flüssiger)
	
	# Zufällig mischen
	directions.shuffle()
	
	# Die erste Richtung nehmen
	current_dir = directions[0]
