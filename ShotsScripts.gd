extends Label

var shoot_count = 0  # Counter to track shots
var max_shots = 30    # Maximum shots before reloading

# Called when the node enters the scene tree for the first time
func _ready():
	update_shot_counter()

# Called from the player script when a shot is fired
func increment_shot():
	shoot_count += 1
	update_shot_counter()
	
	# Check if it's time to reload
	if shoot_count >= max_shots:
		shoot_count = 0
		update_shot_counter()
		return true  # Signal to reload
	return false

# Update the label text
func update_shot_counter():
	text = "Shots: %d/%d" % [shoot_count, max_shots]

# Reset counter (optional if needed separately)
func reset_counter():
	shoot_count = 0
	update_shot_counter()
