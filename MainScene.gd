# ================= MAIN SCENE SCRIPT =================
extends Node3D
# ================= VARIABLES =================
@onready var pause_menu: Control = $HUD/pause_menu
@onready var quit: Button = $HUD/pause_menu/Quit
var paused = false
# ================= PAUSE =================
func _process(_delta):
	if Input.is_action_just_pressed("Pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
# ================= QUIT =================
func _on_quit_pressed() -> void:
	print("Button Pressed")
	get_tree().quit()
