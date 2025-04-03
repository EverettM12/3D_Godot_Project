#3D Godot FPS Project
FPS Movement and Mechanics Script
This script is the backbone of a first-person shooter (FPS) game built in Godot. It manages essential gameplay mechanics such as player movement, camera control, wall running, head bobbing, and shooting.

#Key Features
Player Movement
Walk, Sprint, and Crouch: The player’s speed changes depending on their movement state.

Jumping: Allows the player to jump with a predefined velocity.

Gravity Handling: Ensures proper gravity effects when the player is not grounded.

Camera Controls
First-Person & Third-Person View: Players can switch between first-person and third-person perspectives.

Customizable Sensitivity & Inverted Y-Axis: Adjust mouse sensitivity and toggle an inverted Y-axis if preferred.

Head Bobbing Effect: Adds a touch of realism by slightly moving the camera up and down while walking.

Dynamic Field of View (FOV): The FOV adjusts dynamically, such as expanding when sprinting for a speed effect.

Camera Shake: Subtle shake effects enhance immersion, especially when walking or sprinting.

Wall Running
Wall Detection: Uses raycasting to identify walls suitable for wall running.

Smooth Wall Running Mechanics: Moves the player along a detected wall under the right conditions.

Automatic Timeout: Limits wall running duration to maintain balance and realism.

Shooting Mechanics
Gun Firing Animation: Animates weapon firing for a more engaging shooting experience.

Shot Counter: Keeps track of the number of bullets fired.

Reload System: Prevents shooting while reloading and plays a corresponding animation.

Zoom Feature: Allows players to toggle between a zoomed-in and normal view for better accuracy.

#How the Script Works
_input(event): Handles all player inputs, including movement, jumping, shooting, and switching camera views.

_physics_process(delta): Manages movement logic frame by frame, applying gravity and adjusting FOV as needed.

wall_run_check(): Uses raycasting to check for walls and initiates wall running if conditions are met.

toggle_camera(): Switches between first-person and third-person modes.

adjust_fov(delta): Dynamically modifies the FOV, particularly during sprinting.

start_reload(): Triggers the reload animation and temporarily disables shooting.

_headbob(time) -> Vector3: Introduces a head bobbing effect when the player moves.

_bodycam_shake(delta) -> Vector3: Adds subtle camera shake for a more immersive experience.

#How to Install & Use
Import the script into your Godot project.

Attach it to your player character node.

Set up necessary input actions (e.g., Move_Forward, Jump, Shoot, Sprint, etc.) in Godot’s input map.

Customize values such as WALK_SPEED, SPRINT_SPEED, JUMP_VELOCITY, FOV settings, and sensitivity based on your needs.

#Planned Enhancements
Improved wall running mechanics and animations.

New movement features like sliding and vaulting.

More refined camera effects and shooting mechanics.

#Pause Menu Script for Godot FPS
This script adds a pause menu to your FPS game, allowing players to pause, resume, and exit the game smoothly.

#Key Features
Pause & Resume Functionality
Pause Menu Toggle: The player can open or close the pause menu by pressing the designated pause button (Pause action in the Input Map).

Game Freezing: When paused, Engine.time_scale is set to 0 to stop all in-game activity.

Smooth Resumption: Unpausing restores Engine.time_scale to 1, allowing gameplay to continue normally.

Mouse Control Enhancements
Mouse Locking & Unlocking:

The mouse is locked (MOUSE_MODE_CAPTURED) when the game resumes.

The mouse is unlocked (MOUSE_MODE_VISIBLE) when the game is paused.

Quit Button Functionality
Exit Game Feature: Clicking the Quit button immediately closes the game.

Debug Confirmation: Prints a debug message (Button Pressed) for confirmation when quitting.

#How the Script Works
_process(_delta): Listens for the pause button press and responds accordingly.

_pause_menu(): Toggles the pause menu visibility and adjusts game settings when pausing or resuming.

_on_quit_pressed(): Handles game exit when the Quit button is clicked.

#How to Install & Use
Attach the script to a Node3D responsible for handling the pause menu.

Ensure your UI setup includes:

A Control node named pause_menu.

A Button named Quit inside pause_menu.

Set up the Pause action in Godot’s Input Map to enable menu toggling.

#Planned Enhancements
Adding a resume button and settings menu.

Implementing automatic audio muting when paused.

Introducing smoother transitions between pause and resume states.

Contributions
Feel free to contribute, modify, or enhance this script! Forks and pull requests are welcome.

License
This project is open-source, meaning you're free to use and modify it in your own games!



