extends CanvasLayer
class_name LuviConsole

signal on_command_execute(value: Array[String])

@onready var container: MarginContainer = $Container
@onready var console: RichTextLabel = $Container/Content/Console
@onready var input: LineEdit = $Container/Content/Input

@export_group("Configurations")
@export_range(0, 0, 1, "or_greater") var _message_capacity: int = 64
@export_range(0, 0, 1, "or_greater") var _command_capacity: int = 16
@export var _is_showing: bool = false
@export var _is_repeat_command = false

var is_showing: bool:
	get:
		return _is_showing
	set(value):
		_is_showing = value
		_update_visibility()
		
var message_capacity: int:
	get:
		return _message_capacity
	set(value):
		_message_capacity = value
		_update_log()

var command_capacity: int:
	get:
		return _command_capacity
	set(value):
		_command_capacity = value
		_update_command_capacity()
		
var log_message: Array[String] = []
var log_command_execute: Array[String] = []
var log_command_index: int = -1

func print(value: String) -> void:
	log_message.append(value)
	_update_log()

func clear() -> void:
	log_message.clear()
	_update_log()

func _ready() -> void:
	_update_visibility()
	input.text_submitted.connect(self._on_input_summitted)

func _on_input_summitted(text: String) -> void:
	if text.is_empty():
		return
	if _is_repeat_command:
		log_message.append("[i][color=#FFFF00]>[/color] [color=#00FFFF]" + text + "[/color][/i]")
	log_command_execute.append(text)
	log_command_index = -1
	_update_log()
	input.clear()
	var commands = _split_command_text(text)
	on_command_execute.emit(commands)

func _input(event) -> void:
	if event is InputEventKey:
		if event.is_released() and event.keycode == KEY_F1:
			is_showing = not is_showing
		if _is_showing and not log_command_execute.is_empty():
			if event.is_released() and event.keycode == KEY_UP:
				if log_command_index < 0:
					log_command_index = log_command_execute.size() - 1
				else:
					log_command_index = log_command_index - 1
					if log_command_index < 0:
						log_command_index = 0
				_update_command_input(log_command_index)
				_update_command_capacity()
			if event.is_released() and event.keycode == KEY_DOWN:
				if log_command_index < 0:
					log_command_index = 0
				else:
					log_command_index = log_command_index + 1
					if log_command_index > log_command_execute.size() - 1:
						log_command_index = log_command_execute.size() - 1
				_update_command_input(log_command_index)
				_update_command_capacity()

func _split_command_text(value: String) -> Array[String]:
	var in_quote: bool = false
	var start_index: int = 0
	var end_index: int = 0
	var commands: Array[String] = []
	var cache_quote_type: String = ''
	var cache_text: String = ""
	for chr in value:
		if in_quote:
			if _is_valid_quote(chr) and cache_quote_type == chr:
				in_quote = false
				commands.append(cache_text)
				cache_text = ""
				continue
		else:
			if _is_valid_quote(chr):
				cache_quote_type = chr
				in_quote = true
				continue
			if chr == ' ':
				commands.append(cache_text)
				cache_text = ""
				continue
		cache_text += chr
	if not cache_text.is_empty():
		commands.append(cache_text)
	return commands
	
func _is_valid_quote(char: String) -> bool:
	if char == "\'" or char == "\"":
		return true
	return false

func _update_visibility() -> void:
	container.visible = _is_showing
	if _is_showing:
		log_command_index = -1
		input.grab_focus()
		input.clear()
	else:
		input.release_focus()

func _update_log() -> void:
	if log_message.size() > _message_capacity:
		log_message = log_message.slice(log_message.size() - _message_capacity, log_message.size())
	console.clear()
	for message in log_message:
		console.append_text(message)
		console.newline()

func _update_command_input(index: int) -> void:
	input.text = log_command_execute[index]
	input.caret_column = input.text.length()

func _update_command_capacity() -> void:
	if log_command_execute.size() > _command_capacity:
		log_command_execute = log_command_execute.slice(log_command_execute.size() - _command_capacity, log_command_execute.size())
