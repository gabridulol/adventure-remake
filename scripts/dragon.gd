extends CharacterBody2D

enum State { IDLE, CHASING, DEAD }
var state: State = State.IDLE

@export var speed: float = 60.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $VisionArea

var target: CharacterBody2D = null

func _ready() -> void:
	print("Dragon READY, vision_area =", vision_area)
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO

		State.CHASING:
			if target:
				var direction: Vector2 = (target.global_position - global_position).normalized()
				velocity = direction * speed
			else:
				velocity = Vector2.ZERO
				state = State.IDLE

		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

func _on_vision_body_entered(body: Node) -> void:
	print("VISION ENTER:", body, "groups:", body.get_groups())
	if body.is_in_group("player") and state != State.DEAD:
		target = body
		state = State.CHASING

func _on_vision_body_exited(body: Node) -> void:
	print("VISION EXIT:", body)
	if body == target:
		target = null
		state = State.IDLE
