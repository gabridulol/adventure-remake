extends CharacterBody2D
class_name Player

@export var speed: float = 120.0
@export var item_rotation_speed_deg: float = 720.0
@export var walk_anim_fps: float = 6.0  # velocidade da caminhada (frames por segundo)

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var item_pivot: Node2D = $ItemPivot
@onready var pickup_area: Area2D = $PickupArea

# 8 direções (0..7) em graus:
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

# Paletas: prefixos que viram "prefix + idle" / "prefix + walk"
# 0 = normal -> "idle" / "walk"
# 1..6 = suas cores -> "p1_idle", "p1_walk", etc.
const PALETTE_PREFIXES: Array[String] = [
	"",      # 0 – normal
	"p1_",   # 1 – paleta 1
	"p2_",   # 2 – paleta 2
	"p3_",   # 3 – paleta 3
	"p4_",   # 4 – paleta 4
	"p5_",   # 5 – paleta 5
	"p6_",   # 6 – paleta 6
]

var current_palette: int = 0          # índice da paleta atual
var carried_item: Node2D = null       # item que está sendo carregado (se houver)
var facing_dir_index: int = 0         # última direção de movimento (0..7)
var walk_anim_time: float = 0.0       # acumulador de tempo para anim da caminhada


# =========================
#   PALETA / COR
# =========================
func set_palette(palette_index: int) -> void:
	current_palette = clamp(palette_index, 0, PALETTE_PREFIXES.size() - 1)

@export var respawn_point: NodePath
var _respawn_position: Vector2


func _ready() -> void:
	# calcula posição de respawn
	if respawn_point != NodePath(""):
		var node := get_node_or_null(respawn_point)
		if node and node is Node2D:
			_respawn_position = (node as Node2D).global_position
		else:
			_respawn_position = global_position
	else:
		_respawn_position = global_position


func die() -> void:
	# Aqui você pode tocar uma animação, som, etc.
	print("Player morreu! Respawnando...")

	# dropa item, se quiser
	if carried_item != null:
		drop_item()

	# respawn simples
	global_position = _respawn_position
	velocity = Vector2.ZERO



# =========================
#   LOOP FÍSICO
# =========================
func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = _get_input_dir()
	var is_moving: bool = input_dir.length() > 0.0

	if is_moving:
		input_dir = input_dir.normalized()
		velocity = input_dir * speed
		walk_anim_time += delta
	else:
		velocity = Vector2.ZERO
		walk_anim_time = 0.0

	move_and_slide()

	# Direção SEMPRE baseada no movimento
	if is_moving:
		var angle: float = input_dir.angle()
		facing_dir_index = _dir_index_from_angle(angle)

	_set_animation(facing_dir_index, is_moving)

	# Item na mão gira em direção ao mouse
	if carried_item != null:
		_update_item_rotation(delta)


# =========================
#   INPUT DE MOVIMENTO
# =========================
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


# =========================
#   ROTAÇÃO DO ITEM
# =========================
func _update_item_rotation(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var target_angle: float = (mouse_pos - global_position).angle()

	var max_step: float = deg_to_rad(item_rotation_speed_deg) * delta
	var angle_diff: float = wrapf(target_angle - item_pivot.rotation, -PI, PI)
	var step: float = clamp(angle_diff, -max_step, max_step)

	item_pivot.rotation += step


# =========================
#   DIREÇÃO (ÂNGULO -> 0..7)
# =========================
func _dir_index_from_angle(angle_rad: float) -> int:
	var angle_deg: float = rad_to_deg(angle_rad)
	var best_idx: int = 0
	var best_dist: float = 9999.0

	for i in range(DIR_ANGLES_DEG.size()):
		var dist: float = abs(wrapf(angle_deg - DIR_ANGLES_DEG[i], -180.0, 180.0))
		if dist < best_dist:
			best_dist = dist
			best_idx = i

	return best_idx


# =========================
#   ANIMAÇÃO (USANDO FRAMES)
# =========================
# idle: 8 frames (0..7) → 1 frame por direção
# walk: 16 frames (0..15) → pares (0,1) (2,3) ... (14,15) por direção
func _set_animation(dir_idx: int, moving: bool) -> void:
	var prefix: String = PALETTE_PREFIXES[current_palette]

	if moving:
		var anim_name: String = prefix + "walk"

		# Garante que estamos na animação correta
		if sprite.animation != anim_name:
			sprite.animation = anim_name
			sprite.play()

		# Controle manual de frames
		sprite.speed_scale = 0.0

		# Cada direção ocupa 2 frames consecutivos
		var base_frame: int = dir_idx * 2
		var local_step: int = int(floor(walk_anim_time * walk_anim_fps)) % 2
		sprite.frame = base_frame + local_step
	else:
		var anim_name: String = prefix + "idle"

		if sprite.animation != anim_name:
			sprite.animation = anim_name
			sprite.play()

		# Idle = 1 frame por direção
		sprite.speed_scale = 0.0
		sprite.frame = dir_idx


# =========================
#   PICKUP / DROP DE ITENS
# =========================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if carried_item != null:
			drop_item()
		else:
			pickup_item_from_area()


func pickup_item_from_area() -> void:
	if pickup_area == null:
		return

	var areas: Array[Area2D] = pickup_area.get_overlapping_areas()
	for area in areas:
		if area.is_in_group("itens"):
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
