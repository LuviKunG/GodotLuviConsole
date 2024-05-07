@tool
extends EditorPlugin

class_name LuviConsoleEditor

func _enter_tree():
	print("Luvi Console is active.")
	pass

func _exit_tree():
	print("Luvi console is deactive.")
	pass
