extends Node2D

@export var speed: float = 80.0
@export var roam_radius: float = 200.0
@export var hover_amplitude: float = 6.0
@export var hover_speed: float = 3.5
@export var reach_threshold: float = 8.0
@export var swap_cooldown: float = 1.0

var itens_proximos: Array[Area2D] = []
var item_carregado: Area2D = null

var start_pos: Vector2
var target_pos: Vector2
var rng := RandomNumberGenerator.new()
var last_swap_time: float = 0.0


func _ready():
	rng.randomize()
	start_pos = global_position
	_pick_new_roam_target()


# ----------------------------------------------------------
# DETECÇÃO DE ITENS
# ----------------------------------------------------------
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("itens") and not itens_proximos.has(area):
		itens_proximos.append(area)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("itens"):
		itens_proximos.erase(area)


# ----------------------------------------------------------
# PEGAR E SOLTAR ITENS
# ----------------------------------------------------------
func escolher_item() -> Area2D:
	if itens_proximos.is_empty():
		return null
	if item_carregado != null:
		for it in itens_proximos:
			if it != item_carregado:
				return it
		return null
	return itens_proximos[0]


func pegar_item(item: Area2D) -> void:
	if item == null:
		return

	if item_carregado:
		soltar_item(item_carregado)

	itens_proximos.erase(item)

	item.monitoring = false
	item.monitorable = false

	item.reparent(self)
	item.position = Vector2(0, 12)

	item_carregado = item
	print("Carregando:", item.name)


func soltar_item(item: Area2D) -> void:
	if item == null:
		return

	var world := get_tree().current_scene
	item.reparent(world)
	item.global_position = global_position + Vector2(80, 0)

	item.monitoring = true
	item.monitorable = true
	item_carregado = null


# ----------------------------------------------------------
# MOVIMENTO
# ----------------------------------------------------------
func _physics_process(delta: float) -> void:
	_move_toward_target(delta)

	var now = Time.get_ticks_msec() / 1000.0
	if not itens_proximos.is_empty():
		var alvo = escolher_item()
		if alvo != null:
			if item_carregado == null:
				pegar_item(alvo)
				last_swap_time = now
			elif now - last_swap_time >= swap_cooldown:
				pegar_item(alvo)
				last_swap_time = now


func _move_toward_target(delta: float) -> void:
	var hover = Vector2(0, sin(Time.get_ticks_msec() / 1000.0 * hover_speed) * hover_amplitude)
	if target_pos == null:
		_pick_new_roam_target()

	var dir = (target_pos - global_position)
	if dir.length() > reach_threshold:
		global_position += dir.normalized() * speed * delta
	else:
		_pick_new_roam_target()

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.position = hover


func _pick_new_roam_target() -> void:
	var ang = rng.randf() * PI * 2.0
	var r = rng.randf() * roam_radius
	target_pos = start_pos + Vector2(cos(ang), sin(ang)) * r
