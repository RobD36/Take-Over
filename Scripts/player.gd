extends CharacterBody3D

@export var takeable_scene: PackedScene
@onready var game_manager: Node = %GameManager

const SPEED = 5.0
const TELEPORT_SPEED = 15
const JUMP_VELOCITY = 4.5

@onready var camera: Camera3D = $Camera3D
@onready var ray_cast: RayCast3D = $Camera3D/RayCast
var camera_sens = 50
var look_dir: Vector2

var cap_mouse = true
var moveable = true

var target_position: Vector3
var moving_to_target: bool = false
var check_raycast = true

func _ready():
	# Initialize GameManager callback (this could be a failure handling function)
	game_manager.set_fail_callback(_on_takeover_fail)
	game_manager.set_win_callback(_on_win)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Action button
	if Input.is_action_just_pressed("action"):
		_take_over()
	
	# Free mouse cursor
	if Input.is_action_just_pressed("pause"):
		cap_mouse = !cap_mouse
		
	if cap_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# If moving towards a target, interpolate position smoothly
	if moving_to_target:
		global_transform.origin = global_transform.origin.lerp(target_position, TELEPORT_SPEED * delta)
		if global_transform.origin.distance_to(target_position) < 0.4:
			moving_to_target = false  # Stop moving when close enough

	if moveable:
		# Apply movement
		_rotate_camera(delta)
		move_and_slide()

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.01

func _rotate_camera(delta: float, sens_mod: float = 1.0):
	var input = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	look_dir += input
	rotation.y -= look_dir.x * camera_sens * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5, 1.5)
	look_dir = Vector2.ZERO

func _take_over():
	if check_raycast:
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			
			if collider and collider.is_in_group("takeable"):
				var old_position = global_transform.origin
				var new_position = collider.global_transform.origin
				
				# Set the target position and start moving smoothly
				target_position = new_position
				moving_to_target = true
				
				# Delete target and place new one at old position
				collider.queue_free()
				#_spawn_takeable(old_position)
				
				# Start the takeover timer from the GameManager
				game_manager.start_takeover_timer()

func _spawn_takeable(position: Vector3):
	if takeable_scene:
		var new_takeable = takeable_scene.instantiate()
		new_takeable.global_transform.origin = position
		get_parent().add_child(new_takeable)

# Called when takeover fails
func _on_takeover_fail():
	moveable = false
	check_raycast = false
	print("You failed to take over the character in time!")

func _on_win():
	moveable = false
	check_raycast = false
