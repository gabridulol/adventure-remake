extends Node2D

# ---------- Movimento ----------
@export var speed: float = 80.0
@export var roam_radius: float = 200.0
@export var hover_amplitude: float = 6.0
@export var hover_speed: float = 3.5
@export var reach_threshold: float = 8.0

# ---------- Cooldown de troca ----------
@export var swap_cooldown: float = 1.0  # segundos

# ---------- Patrulha pelos pontos ----------
@export var patrol_points: Array[NodePath] = []

# ---------- Variação de trajetória ----------
@export var wander_strength: float = 0.6  # 0 = reta, 1+ = bem caótico

# ---------- Estado de itens ----------
var itens_proximos: Array[Area2D] = []
var item_carregado: Node2D = null
var last_swap_time: float = -1000.0

# ---------- Movimento interno ----------
var start_pos: Vector2
var target_pos: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wander_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	start_pos = global_position
	target_pos = start_pos
	_pick_new_roam_target()

	# Toca a animação do morcego
	if has_node("Sprite2D") and $Sprite2D is AnimatedSprite2D:
		$Sprite2D.animation = "voando_1"  
		$Sprite2D.play()



# ===================================================================
#  DETECÇÃO DE ITENS (apenas gerencia lista)
# ===================================================================

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not area.is_in_group("items"):
		return

	if not itens_proximos.has(area):
		itens_proximos.append(area)


func _on_area_2d_area_exited(area: Area2D) -> void:
	if itens_proximos.has(area):
		itens_proximos.erase(area)


func escolher_item() -> Area2D:
	if itens_proximos.is_empty():
		return null

	# Se já estou carregando algo, evito escolher a área do item atual
	if item_carregado != null and item_carregado.has_node("Area2D"):
		var area_atual: Area2D = item_carregado.get_node("Area2D")
		for a: Area2D in itens_proximos:
			if a != area_atual:
				return a
		# só tem a área do item já carregado
		return null

	# Sem item carregado: pega o primeiro da lista
	return itens_proximos[0]


# ===================================================================
#  PEGAR / SOLTAR ITEM
# ===================================================================

func pegar_item(area: Area2D) -> void:
	if area == null:
		return

	var item: Node2D = area.get_parent() as Node2D

	# Se já existe item carregado → solta primeiro
	if item_carregado:
		soltar_item(item_carregado)

	# Remove a área da lista, se ainda estiver lá
	if itens_proximos.has(area):
		itens_proximos.erase(area)

	# Desativa colisão enquanto está sendo carregado
	area.monitoring = false
	area.monitorable = false

	# Reparent pro morcego
	item.reparent(self)
	item.position = Vector2(0, 12)

	item_carregado = item
	print("Carregando:", item.name)


func soltar_item(item: Node2D) -> void:
	if item == null:
		return

	var world: Node = get_tree().current_scene
	item.reparent(world)

	# Solta um pouco à direita pra não re-colidir no mesmo frame
	item.global_position = global_position + Vector2(80, 0)

	# Reativa Area2D do item
	if item.has_node("Area2D"):
		var area: Area2D = item.get_node("Area2D")
		area.monitoring = true
		area.monitorable = true

	item_carregado = null


# ===================================================================
#  LOOP PRINCIPAL: movimento + escolha de item com cooldown
# ===================================================================

func _physics_process(delta: float) -> void:
	_move_toward_target(delta)

	if itens_proximos.is_empty():
		return

	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var alvo: Area2D = escolher_item()
	if alvo == null:
		return

	if item_carregado == null:
		# sem item: pega direto
		pegar_item(alvo)
		last_swap_time = now
	else:
		# já tem item: só troca se passou o cooldown
		if now - last_swap_time >= swap_cooldown:
			pegar_item(alvo)
			last_swap_time = now


# ===================================================================
#  MOVIMENTO COM WANDER (trajetória não retilínea)
# ===================================================================

func _move_toward_target(delta: float) -> void:
	# hover visual
	var hover: Vector2 = Vector2(
		0,
		sin(float(Time.get_ticks_msec()) / 1000.0 * hover_speed) * hover_amplitude
	)

	var to_target: Vector2 = target_pos - global_position
	var dist: float = to_target.length()

	if dist > reach_threshold:
		var base_dir: Vector2 = to_target.normalized()

		# direção aleatória suave
		var random_dir: Vector2 = Vector2(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0)
		)
		if random_dir != Vector2.ZERO:
			random_dir = random_dir.normalized()

		# 0.08 controla quão rápido o "rumo" muda
		wander_offset = wander_offset.lerp(random_dir, 0.08)

		# quanto mais longe, mais forte o wander
		var wander_factor: float = clamp(dist / roam_radius, 0.0, 1.0)

		var final_dir: Vector2 = (base_dir + wander_offset * wander_strength * wander_factor).normalized()

		global_position += final_dir * speed * delta
	else:
		_pick_new_roam_target()

	if has_node("Sprite2D"):
		$Sprite2D.position = hover


func _pick_new_roam_target() -> void:
	# Se tiver pontos de patrulha configurados, usa eles
	if patrol_points.size() > 0:
		var idx: int = rng.randi_range(0, patrol_points.size() - 1)
		var path: NodePath = patrol_points[idx]
		var node: Node = get_node_or_null(path)
		if node != null and node is Node2D:
			var p: Node2D = node as Node2D
			target_pos = p.global_position
			return

	# Fallback: posição aleatória num raio em volta do start_pos
	var ang: float = rng.randf() * TAU
	var r: float = rng.randf() * roam_radius
	target_pos = start_pos + Vector2(cos(ang), sin(ang)) * r
