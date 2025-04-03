extends Node3D

@onready var pause_menu: Control = $pause_menu
@onready var quit: Button = $pause_menu/Quit

var paused = false

func _process(_delta):
	if Input.is_action_just_pressed("Pause"):
		_pause_menu()

func _pause_menu():
	if paused:
		# Return to captured mouse mode and hide pause menu
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		# Set mouse mode to visible and show the pause menu
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		pause_menu.show()
		Engine.time_scale = 0
		
	paused = !paused


func _on_quit_pressed() -> void:
	print("Button Pressed")
	get_tree().quit()
