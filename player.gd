extends Area2D
signal hit

@export var speed = 400 # How fast the player will move (pixels/sec).
@export var idle_swing_amount = 0.1  # Maximum swing angle (in radians)
@export var idle_swing_speed = 2.0  # Swing speed

@export var use_joystick = false
@onready var move_joystick: VirtualJoystick = get_node("MoveJoystick")

var screen_size # Size of the game window.
var rotation_speed = 5

var touch_position = Vector2.ZERO
var is_touching = false
var target_angle = 0
var move_direction = Vector2.ZERO # Movement direction
var time = 0.0  # Variable for sinusoidal movement

var last_rotation = 0.0  # Last rotation angle before releasing the button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()
	
func _process(delta):
	time += delta
	if use_joystick:
		# Control using joystick
		print('move_joystick', move_joystick)
		var joystick_output = move_joystick.get_output()
		move_direction = joystick_output.normalized()

		if move_direction.length_squared() > 0:
			target_angle = move_direction.angle()
			rotation = lerp_angle(rotation, target_angle + PI / 2, rotation_speed * delta)
			last_rotation = rotation
			$AnimatedSprite2D.play()
		else:
			# Floating effect when there's no joystick input
			rotation = last_rotation + sin(time * idle_swing_speed) * idle_swing_amount
			$AnimatedSprite2D.stop()

		# Movement
		position += move_direction * speed * delta
		position = position.clamp(Vector2.ZERO, screen_size)
	if is_touching:
		# Smooth rotation
		rotation = lerp_angle(rotation, target_angle + PI / 2, rotation_speed * delta)
		last_rotation = rotation  # Запоминаем последний угол
	else:
		# Floating effect when there's no joystick input
		rotation = last_rotation + sin(time * idle_swing_speed) * idle_swing_amount
	
	# Movement
	position += move_direction * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	# Animation playback
	if move_direction.length() > 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
			
func _input(event):
	if not use_joystick:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			if event.is_pressed():
				is_touching = true
				touch_position = event.position
				update_direction()
			elif event.is_released():
				is_touching = false
				move_direction = Vector2.ZERO

func update_direction():
	move_direction = (touch_position - position).normalized()
	target_angle = move_direction.angle()

func _on_body_entered(body: Node2D) -> void:
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
