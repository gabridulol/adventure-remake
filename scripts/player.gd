extends CharacterBody2D

@export var speed: float = 120.0

func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		input_dir.x += 1

	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		input_dir.x -= 1

	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		input_dir.y += 1

	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		input_dir.y -= 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
