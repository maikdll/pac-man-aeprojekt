extends Node

var socket = WebSocketPeer.new()
var url = "ws://localhost:8765"

func _ready():
	print("Verbinde mit LED-Bridge...")
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Fehler beim Verbindungsaufbau: ", err)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			socket.get_packet() 
			
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("Verbindung geschlossen. Code: ", code, " Grund: ", reason)
		set_process(false) 

func send_effect(chain: String, effect_type: String, color: Color, segment: int = 99):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		
		var data = {
			"cmd": "effect",
			"chain": chain,
			"type": effect_type,
			"segment": segment, 
			"color": {
				"r": int(color.r * 255),
				"g": int(color.g * 255),
				"b": int(color.b * 255)
			},
			"speed": 50,
			"repeat": 1,
			"priority": 2
		}
		
		var json_string = JSON.stringify(data)
		socket.send_text(json_string)
		
		print("Befehl gesendet: ", json_string)
		
	else:
		print("Senden fehlgeschlagen: Websocket noch nicht verbunden.")

func _input(event):
	if event.is_action_pressed("ui_accept"): 
		print("Leertaste gedrückt! Feuere Effekt ab...")
		send_effect("A", "chase", Color.RED)
