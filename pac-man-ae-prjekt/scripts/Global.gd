extends Node

var level = 1
var health = 3
var score = 0
var isGameStopped = false;
var speedGhost = 0.6;
var speedGhostRed = 1;
var speedGhostCyan = 1;
var speedGhostPink = 1;
var speedGhostOrange = 1;
var speedPlayer = 1;
var isIntermissionMode = false;
var eatGhostScore = 200;
var dots_eaten = 0
var remainingPoints = 500;
var eaten_points_positions = {}
var died_in_level = false

var socket = WebSocketPeer.new()
var ws_url = "ws://localhost:8765"

const CHAIN_A = "A"
const CHAIN_B = "B"
const SEG_ALL = 99
const SEG_A_MARQUEE = 0
const SEG_A_CONTROL_PANEL = 5

const SAVE_PATH = "user://leaderboard.save"
var leaderboard = [
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0},
	{"name": "Empty", "score": 0}
]

func _process(_delta):
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			socket.get_packet()

func send_effect(chain: String, effect_type: String, color: Color, segment: int = SEG_ALL, speed: int = 50, repeat_count: int = -1):
	await get_tree().create_timer(0.2).timeout
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
			"speed": speed,
			"repeat": repeat_count,
			"length": 10,
			"priority": 2
		}
		print("Sending effect!...")
		socket.send_text(JSON.stringify(data))
	else:
		print("FEHLER: Socket nicht offen! Status ist: ", socket.get_ready_state())
func _ready():
	var err = socket.connect_to_url(ws_url)
	if err != OK:
		print("Global: Fehler beim Verbindungsaufbau zur LED Bridge")

func save_leaderboard():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(leaderboard)
	
func load_leaderboard():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		leaderboard = file.get_var()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		get_tree().quit()

func update_leaderboard(new_name: String):
	leaderboard.append({"name": new_name, "score": Global.score})
	
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	
	leaderboard = leaderboard.slice(0, 5)
	
	save_leaderboard()

func resetLedGameplay():
	send_effect(Global.CHAIN_A, "chase", Color.YELLOW, Global.SEG_ALL, 40, -1)
	send_effect(Global.CHAIN_B, "pulse", Color.YELLOW, Global.SEG_ALL, 70, -1)
