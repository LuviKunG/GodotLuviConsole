## Luvi Console for Godot Engine.
## A simple in-game console for Godot Engine that can perform custom commands.

class_name LuviConsole 
extends CanvasLayer

#region Constants

## The key code to toggle the console.
const KEY_TOGGLE_CONSOLE = KEY_F1

#endregion

#region Signals

## Signals emitted when a command is executed.
signal on_command_execute(value: Array[String])

#endregion

#region Node Path

@onready var container: MarginContainer = $Container
@onready var console: RichTextLabel = $Container/Content/Console
@onready var input: LineEdit = $Container/Content/Input

#endregion

#region Export Variables

@export_group("Configurations")
## The maximum number of messages that can be displayed in the console.
@export_range(0, 0, 1, "or_greater") var _message_capacity: int = 64
## The maximum number of commands that can be stored in the command history.
@export_range(0, 0, 1, "or_greater") var _command_capacity: int = 16
## Determines whether the console is visible or not.
@export var _is_showing: bool = false
## Determines whether the console will log the command when the command is executed.
@export var _is_repeat_command = false

#endregion

#region Property

## Determines whether the console is visible or not.
var is_showing: bool:
	get:
		return _is_showing
	set(value):
		_is_showing = value
		_update_visibility()
		
## The maximum number of messages that can be displayed in the console.
var message_capacity: int:
	get:
		return _message_capacity
	set(value):
		_message_capacity = value
		_update_log()

## The maximum number of commands that can be stored in the command history.
var command_capacity: int:
	get:
		return _command_capacity
	set(value):
		_command_capacity = value
		_update_command_capacity()

#endregion

#region Private variables

var log_message: Array[String] = []
var log_command_execute: Array[String] = []
var log_command_index: int = -1

#endregion

#region Public functions

func print(value: String) -> void:
	log_message.append(value)
	_update_log()

func clear() -> void:
	log_message.clear()
	_update_log()

#endregion

#region Override functions

func _ready() -> void:
	_update_visibility()
	input.text_submitted.connect(self._on_input_summitted)

func _input(event) -> void:
	if event is InputEventKey:
		if event.is_released() and event.keycode == KEY_TOGGLE_CONSOLE:
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

#endregion

#region Private functions

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

#endregion