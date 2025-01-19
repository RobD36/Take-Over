extends Node

@export var time_limit: float = 2  # Time limit for takeover
var takeover_timer: float = 0.0
var takeover_in_progress: bool = false
var on_fail_callback: Callable  # A callback function to call on failure
var on_win_callback: Callable

@onready var time_label: Label = $TimeLabel
@onready var game_label: Label = $GameLabel
@onready var instruction_label: Label = $InstructionLabel
	
# Called every frame
func _process(delta: float) -> void:
	if takeover_in_progress:
		time_label.text = "Time left: " + str(snapped(takeover_timer, 0.01))
		takeover_timer -= delta
		
		var takeable_objects = get_tree().get_nodes_in_group("takeable")
		if takeable_objects.size() == 0:
			on_win_callback.call()
			game_label.text = "You win!!"
			takeover_in_progress = false
			instruction_label.text = "Press 'R' to reset"
		else:
			if takeover_timer <= 0:
				_fail_takeover()
	
# Start the takeover timer
func start_takeover_timer():
	takeover_in_progress = true
	takeover_timer = time_limit
	game_label.text = ""
	instruction_label.text = ""

func reset():
	time_label.text = "Time left: -"
	game_label.text = ""
	instruction_label.text = ""

# Callback for handling failure (can be set externally)
func set_fail_callback(callback: Callable):
	on_fail_callback = callback

func set_win_callback(callback: Callable):
	on_win_callback = callback

# Called when takeover fails
func _fail_takeover():
	takeover_in_progress = false
	if on_fail_callback:
		time_label.text = "Time left: 0.00"
		game_label.text = "Game Over"
		instruction_label.text = "Press 'R' to reset"
		on_fail_callback.call()  # Call the failure callback to notify the game
