extends CanvasLayer

@onready var label = Label.new()
@onready var bg_panel = ColorRect.new()
var overlay_active := false

func _ready():
	self.layer = 128
	visible = false
	_setup_ui()

func _setup_ui():
	bg_panel.color = Color(0, 0, 0, 0.7)
	bg_panel.custom_minimum_size = Vector2(180, 115)
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

func _process(_delta):
	if not visible:
		return
		
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var cpu = Performance.get_monitor(Performance.TIME_PROCESS) * 1000
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var dc = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)

	if fps >= 55:
		label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	elif fps >= 30:
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))

	label.text = "SYSTEM [P]\n"
	label.text += "──────────\n"
	label.text += "FPS  │ %d\n" % fps
	label.text += "CPU  │ %.2fms\n" % cpu
	label.text += "RAM  │ %.1fMB\n" % mem
	label.text += "NODE │ %d\n" % nodes
	label.text += "DRAW │ %d" % dc
