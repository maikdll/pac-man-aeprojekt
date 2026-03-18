extends CanvasLayer

@onready var bg_panel = ColorRect.new()
@onready var label = Label.new()
var overlay_active := false

var update_interval := 0.25 
var time_passed := 0.0
var current_color_state := -1 

# --- NEU: System-Variablen für Cross-Platform ---
var os_name := "Unknown"
var video_adapter := "Unknown"

func _ready():
	self.layer = 128
	visible = false
	
	# Das Skript checkt beim Start einmalig, auf welchem Betriebssystem es ist!
	# (Gibt "Windows", "macOS" oder "Linux" zurück)
	os_name = OS.get_name() 
	video_adapter = RenderingServer.get_video_adapter_name()
	
	_setup_ui()

func _setup_ui():
	bg_panel.color = Color(0, 0, 0, 0.7)
	# Das Panel ein kleines bisschen breiter gemacht für die System-Infos
	bg_panel.custom_minimum_size = Vector2(175, 115) 
	bg_panel.position = Vector2(10, 10)
	add_child(bg_panel)

	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 8)
	label.position = Vector2(18, 18)
	add_child(label)

func _input(event):
	if event.is_action_pressed("toggle_performance"):
		overlay_active = !overlay_active
		visible = overlay_active
		time_passed = update_interval # Sofortiges Update beim Einblenden

func _process(delta):
	if not visible:
		return
		
	time_passed += delta
	if time_passed < update_interval:
		return
	time_passed = 0.0 
		
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var cpu = Performance.get_monitor(Performance.TIME_PROCESS) * 1000
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var dc = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)

	# --- DER FIX FÜR LINUX RAM ---
	# Fragt die Engine direkt nach Bytes und rechnet in Megabytes um.
	var mem_bytes = OS.get_static_memory_usage()
	var mem = mem_bytes / 1048576.0 

	var new_state = 0
	if fps >= 55: new_state = 2
	elif fps >= 30: new_state = 1

	if current_color_state != new_state:
		current_color_state = new_state
		if new_state == 2:
			label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		elif new_state == 1:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	# --- DYNAMISCHER TEXT FÜR JEDES OS ---
	# Zeigt jetzt dynamisch z.B. "SYSTEM [macOS]" oder "SYSTEM [Linux]" an
	var title = "SYSTEM [%s]" % os_name
	
	label.text = title + "\n"
	label.text += "───────────────────\n"
	label.text += "FPS  │ %d\n" % fps
	label.text += "CPU  │ %.2fms\n" % cpu
	label.text += "RAM  │ %.1f MB\n" % mem
	label.text += "NODE │ %d\n" % nodes
	label.text += "DRAW │ %d\n" % dc
	
	# Bonus-Feature: Zeigt die Grafikkarte (GPU) an, um zu sehen, 
	# ob Linux z.B. den richtigen Grafiktreiber nutzt!
	label.text += "GPU  │ " + video_adapter.substr(0, 12)
