extends Node

var socket = WebSocketPeer.new()

var url = "ws://DEINE_SERVER_IP_HIER" 

func _ready():
	print("Verbinde mit LED-Server...")
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Fehler beim Verbindungsaufbau: ", err)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("Verbindung geschlossen. Code: ", code, " Grund: ", reason)
		set_process(false) 

func send_led_color(color: Color):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var data = {
			"r": int(color.r * 255),
			"g": int(color.g * 255),
			"b": int(color.b * 255)
		}
		var json_string = JSON.stringify(data)
		
		socket.put_packet(json_string.to_utf8_buffer())
		print("Farbe gesendet: ", json_string)
		
	else:
		print("Senden fehlgeschlagen: Keine offene Verbindung.")
