class_name ScreenOutputClass extends CanvasLayer

@onready var install_path = self.get_script().get_path().trim_suffix("output.gd")

var log_id: int = 1

var _debug_enabled: bool = false
var _show_timestamp: bool
var _font_color: String
var _background_color: String
var _font_size: float
var _anchor: int
var _save_logs: bool = false
var _save_path: String = "user://"
var _size: Vector2 = Vector2()

@onready var _config_path: String = install_path + "plugin.cfg"
var _plugin_config: ConfigFile

@onready var main_control: Control = $Control
@onready var log_label: RichTextLabel = $Control/RichTextLabel
@onready var color_rect: ColorRect = $Control/RichTextLabel/ColorRect

var start: int = 0

const ANCHORS: Dictionary = {
	"TOP_LEFT" : {
		"anchor_left" : 0,
		"anchor_top" : 0,
		"anchor_right" : 0,
		"anchor_bottom" : 0,
		"grow_horizontal" : 1,
		"grow_vertical": 1
	},
	"TOP_RIGHT" : {
		"anchor_left" : 1,
		"anchor_top" : 0,
		"anchor_right" : 1,
		"anchor_bottom" : 0, 
		"grow_horizontal" : 0,
		"grow_vertical": 1
	},
	"BOTTOM_RIGHT" : {
		"anchor_left" : 1,
		"anchor_top" : 1,
		"anchor_right" : 1,
		"anchor_bottom" : 1,
		"grow_horizontal" : 0,
		"grow_vertical": 0
	},
	"BOTTOM_LEFT" : {
		"anchor_left" : 0,
		"anchor_top" : 1,
		"anchor_right" : 0,
		"anchor_bottom" : 1,
		"grow_horizontal" : 1,
		"grow_vertical": 0
	}
}

func _ready():
	visible = false
	
	_load_config()
	_setup()
	
	if _show_timestamp:
		start = Time.get_ticks_msec()
	
	# Set Keybind
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.ctrl_pressed = true
	event.shift_pressed = true
	
	if !InputMap.has_action("screen_output_toggle"):
		InputMap.add_action("screen_output_toggle")
	InputMap.action_add_event("screen_output_toggle", event)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("screen_output_toggle"):
		visible = !visible

#func _set_control_anchor(control: Control,anchor: Dictionary):
	# As of 4.1, not tested again in 4.2
	# THIS FUNC IS ESSENTIAL
	# The built-in Control.LayoutPreset options don't work properly
	# likely Godot bug
	#
	#control.anchor_left = anchor["anchor_left"]
	#control.anchor_top = anchor["anchor_top"]
	#control.anchor_right = anchor["anchor_right"]
	#control.anchor_bottom = anchor["anchor_bottom"] 
	#
	#control.grow_horizontal = anchor["grow_horizontal"]
	#control.grow_vertical = anchor["grow_vertical"]

func _setup():
	log_label.custom_minimum_size.x = DisplayServer.window_get_size().x / 6
	log_label.custom_minimum_size.y = DisplayServer.window_get_size().y / 3
	
	log_label.size = _size
	
	log_label.add_theme_font_size_override("normal_font_size", _font_size)
	log_label.add_theme_color_override("default_color", Color(_font_color))
	
	match _anchor:
		0: # Top-Left
			#_set_control_anchor(log_label, ANCHORS["TOP_LEFT"])
			log_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
			
		1: # Top-Right
			#_set_control_anchor(log_label, ANCHORS["TOP_RIGHT"])
			log_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		2: # Bottom-Left
			#_set_control_anchor(log_label, ANCHORS["BOTTOM_LEFT"])
			log_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		3: # Bottom-Right
			#_set_control_anchor(log_label, ANCHORS["BOTTOM_RIGHT"])
			log_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	
	color_rect.color = Color(_background_color)
	
	visible = _debug_enabled
	
 
func _load_config():
	_plugin_config = ConfigFile.new()
	
	var err = _plugin_config.load(_config_path)
	
	if err != OK:
		printerr("Screen Output: Failed to load config. %s might be damaged or missing." % _config_path)
		return

	_debug_enabled = bool(_plugin_config.get_value("config", "debug_enabled"))
	_show_timestamp = bool(_plugin_config.get_value("config", "show_timestamp"))
	_font_color = _plugin_config.get_value("config", "font_color")
	_background_color = _plugin_config.get_value("config", "background_color")
	_font_size = float(_plugin_config.get_value("config", "font_size"))
	_anchor = int(_plugin_config.get_value("config", "anchor"))
	_save_logs = bool(_plugin_config.get_value("config", "save_logs"))
	_save_path = str(_plugin_config.get_value("config", "save_path"))
	log_id = int(_plugin_config.get_value("config", "log_id"))
	_size.x = int(_plugin_config.get_value("config", "size_x"))
	_size.y = int(_plugin_config.get_value("config", "size_y"))
	
	print(_font_color)

func _save_config():
	_plugin_config.set_value("config", "log_id", log_id)
	
	_plugin_config.save(_config_path)


## Prints a message to the ScreenOutput. Works similar to the default output in the Editor.
## If show_timestamp is enabled, a timestamp will also be displayed in yellow.
func print(message: String):
	if not _debug_enabled:
		return
	
	log_label.append_text(" > " + message)

	if _show_timestamp:
		log_label.push_indent(1)
		log_label.append_text("[color=yellow]%s[/color]" % _get_timestamp())
		log_label.pop()
	
	log_label.newline()

## returns a timestamp since Game launch in XXmin:XXs:XXms format.
func _get_timestamp() -> String:
	var time_ms: int = Time.get_ticks_msec() - start
	var time_s: int = 0
	var time_min: int = 0
	
	# get s from ms
	time_s = time_ms / 1000
	
	# get min from s
	time_min = time_s / 60
	
	# cap ms and s
	time_ms -= (time_s * 1000)
	time_s -= (time_min * 60)
	
	var timestamp_string: String = "%dmin %ds %dms" % [time_min, time_s, time_ms]
	
	return timestamp_string

## if save_logs is true, this is triggered on Game close.
## The log is saved to the configured save_path.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _save_logs:
		
		_save_path.replace("\\", "/")
		
		if !_save_path.ends_with("/"):
			_save_path += "/"
		
		if !DirAccess.dir_exists_absolute(_save_path):
			DirAccess.make_dir_absolute(_save_path)
			
		var file := FileAccess.open(_save_path + "ScreenOutput-LOG-%d.txt" % log_id, FileAccess.WRITE)
		file.store_string(log_label.get_parsed_text())
		file.close()
		log_id += 1
		
		_save_config()
