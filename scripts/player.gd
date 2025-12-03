extends CharacterBody2D
class_name Player

@export var speed: float = 120.0
@export var item_rotation_speed_deg: float = 720.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var item_pivot: Node2D = $ItemPivot
@onready var pickup_area: Area2D = $PickupArea

# 8 direções (0..7) em graus
# 0: cima, 1: cima-direita, 2: direita, 3: baixo-direita,
# 4: baixo, 5: baixo-esquerda, 6: esquerda, 7: cima-esquerda
const DIR_ANGLES_DEG: Array[float] = [
	-90.0,  # up
	-45.0,  # up-right
	 0.0,   # right
	 45.0,  # down-right
	 90.0,  # down
	135.0,  # down-left
	180.0,  # left
	-135.0  # up-left
]

var carried_item: Node2D = null
var facing_dir_index: int = 0  # última direção de movimento (0..7)


func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = _get_input_dir()
	var is_moving: bool = input_dir.length() > 0.0

	# Movimento
	if is_moving:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Direção do personagem SEMPRE baseada no movimento, não no mouse
	if is_moving:
		var angle: float = input_dir.angle()
		facing_dir_index = _dir_index_from_angle(angle)

	_set_animation(facing_dir_index, is_moving)

	# Se estiver segurando um item, ele gira em direção ao mouse
	if carried_item != null:
		_update_item_rotation(delta)


func _get_input_dir() -> Vector2:
	var dir: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		dir.x += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_down"):
		dir.y += 1.0
	if Input.is_action_pressed("move_up"):
		dir.y -= 1.0

	return dir


func _update_item_rotation(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var target_angle: float = (mouse_pos - global_position).angle()

	var max_step: float = deg_to_rad(item_rotation_speed_deg) * delta
	var angle_diff: float = wrapf(target_angle - item_pivot.rotation, -PI, PI)
	var step: float = clamp(angle_diff, -max_step, max_step)

	item_pivot.rotation += step


func _dir_index_from_angle(angle_rad: float) -> int:
	var angle_deg: float = rad_to_deg(angle_rad)
	var best_idx: int = 0
	var best_dist: float = 9999.0

	for i in DIR_ANGLES_DEG.size():
		var dist: float = abs(wrapf(angle_deg - DIR_ANGLES_DEG[i], -180.0, 180.0))
		if dist < best_dist:
			best_dist = dist
			best_idx = i

	return best_idx


func _set_animation(dir_idx: int, moving: bool) -> void:
	var anim_name: String
	if moving:
		anim_name = "walk_" + str(dir_idx)
	else:
		anim_name = "idle_" + str(dir_idx)

	if sprite.animation != anim_name:
		sprite.play(anim_name)


# -----------------------------
# Pickup / Drop de itens
# -----------------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("1")
		if carried_item != null:
			print("2")
			drop_item()
		else:
			print("3")
			pickup_item_from_area()


func pickup_item_from_area() -> void:
	if pickup_area == null:
		print("Não tem nada")
		return

	var areas: Array[Area2D] = pickup_area.get_overlapping_areas()
	print("tentando pegar")
	for area in areas:
		if area.is_in_group("items"):
			print("Pegandoooo Ae")
			pickup_item(area)
			return


func pickup_item(item: Node2D) -> void:
	if carried_item != null:
		return

	carried_item = item

	var parent: Node = item.get_parent()
	if parent != null:
		parent.remove_child(item)

	item_pivot.add_child(item)
	item.position = Vector2(16.0, 0.0)  # ajusta pra caber na mão


func drop_item() -> void:
	if carried_item == null:
		return

	var item: Node2D = carried_item
	carried_item = null

	item_pivot.remove_child(item)
	get_parent().add_child(item)

	item.global_position = global_position + Vector2(16.0, 0.0).rotated(item_pivot.rotation)
