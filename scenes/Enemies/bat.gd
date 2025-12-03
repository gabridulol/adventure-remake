extends Node2D
class_name Bat

# ---------- Movimento ----------
@export var speed: float = 80.0
@export var roam_radius: float = 200.0
@export var hover_amplitude: float = 6.0
@export var hover_speed: float = 3.5
@export var reach_threshold: float = 8.0

# ---------- Cooldown de troca ----------
@export var swap_cooldown: float = 1.0  # segundos entre trocas

# ---------- Patrulha por pontos opcionais ----------
@export var patrol_points: Array[NodePath] = []

# ---------- Variação de trajetória ----------
@export var wander_strength: float = 0.6  # 0 = reta, 1+ = bem caótico

# ---------- Estado de itens ----------
var nearby_items: Array[Area2D] = []   # itens dentro da DetectionArea
var carried_item: Area2D = null        # item que o morcego está carregando
var last_swap_time: float = -1000.0    # última vez que trocou/pegou item

# ---------- Movimento interno ----------
var start_pos: Vector2
var target_pos: Vector2
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wander_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	rng.randomize()
	start_pos = global_position
	_pick_new_roam_target()

	# Animação do morcego (opcional)
	if has_node("Sprite2D"):
		var anim_sprite := $Sprite2D as AnimatedSprite2D
		if anim_sprite:
			anim_sprite.animation = "voando_1"
			anim_sprite.play()


# ===================================================================
#  DETECÇÃO DE ITENS (lista de itens próximos)
#  O DetectionArea deve ser um filho Area2D chamado "DetectionArea"
#  com sinais area_entered/area_exited conectados aqui.
# ===================================================================

func _on_DetectionArea_area_entered(area: Area2D) -> void:
	if not area.is_in_group("itens"):
		return

	if not nearby_items.has(area):
		nearby_items.append(area)


func _on_DetectionArea_area_exited(area: Area2D) -> void:
	if nearby_items.has(area):
		nearby_items.erase(area)


func _pick_item_candidate() -> Area2D:
	if nearby_items.is_empty():
		return null

	# Se já estou carregando um item, tento pegar outro diferente
	if carried_item != null:
		for a in nearby_items:
			if a != carried_item:
				return a
		# Só tem o próprio item carregado dentro da área
		return null

	# Sem item carregado: pega o primeiro da lista
	return nearby_items[0]


# ===================================================================
#  PEGAR / SOLTAR ITEM
#  Aqui o "item" é SEMPRE o root Area2D da cena do item
# ===================================================================

func _pickup_item(item_area: Area2D) -> void:
	if item_area == null:
		return

	# Se já existe item carregado → solta primeiro
	if carried_item != null:
		_drop_item()

	# Evita que fique na lista enquanto carregado
	if nearby_items.has(item_area):
		nearby_items.erase(item_area)

	# Desativa colisão/monitoramento enquanto está sendo carregado
	item_area.monitoring = false
	item_area.monitorable = false

	# Reparent pro morcego (mantendo posição global)
	item_area.reparent(self, true)
	# Ajusta posição local (como se estivesse "pendurado")
	item_area.position = Vector2(0, 12)

	carried_item = item_area
	print("Morcego pegou item:", carried_item.name)


func _drop_item() -> void:
	if carried_item == null:
		return

	var item := carried_item
	carried_item = null

	# Reparent pro mundo atual (cena raiz)
	var world: Node = get_tree().current_scene
	item.reparent(world, true)

	# Solta um pouco à direita pra não re-colidir imediatamente
	item.global_position += Vector2(80, 0)

	# Reativa a detecção da área do item
	item.monitoring = true
	item.monitorable = true

	print("Morcego soltou item:", item.name)


# ===================================================================
#  LOOP PRINCIPAL: movimento + lógica de pegar/trocar item
# ===================================================================

func _physics_process(delta: float) -> void:
	_move_toward_target(delta)
	_update_item_logic()


func _update_item_logic() -> void:
	if nearby_items.is_empty():
		return

	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var alvo: Area2D = _pick_item_candidate()
	if alvo == null:
		return

	if carried_item == null:
		# Não está carregando nada: pega direto
		_pickup_item(alvo)
		last_swap_time = now
	else:
		# Já está com item: troca só se passou o cooldown
		if now - last_swap_time >= swap_cooldown:
			_pickup_item(alvo)
			last_swap_time = now


# ===================================================================
#  MOVIMENTO COM WANDER (trajetória não retilínea) + hover visual
# ===================================================================

func _move_toward_target(delta: float) -> void:
	# Efeito de "pairar" vertical
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

		# 0.08 controla quão rápido a direção "querida" muda
		wander_offset = wander_offset.lerp(random_dir, 0.08)

		# quanto mais longe do alvo, mais forte o wander
		var wander_factor: float = clamp(dist / roam_radius, 0.0, 1.0)

		var final_dir: Vector2 = (base_dir + wander_offset * wander_strength * wander_factor).normalized()

		global_position += final_dir * speed * delta
	else:
		_pick_new_roam_target()

	# Aplica o hover só no Sprite2D (visual)
	if has_node("Sprite2D"):
		$Sprite2D.position = hover


func _pick_new_roam_target() -> void:
	# Se tiver pontos de patrulha configurados, usa um deles
	if patrol_points.size() > 0:
		var idx: int = rng.randi_range(0, patrol_points.size() - 1)
		var path: NodePath = patrol_points[idx]
		var node: Node = get_node_or_null(path)
		if node != null and node is Node2D:
			var p: Node2D = node as Node2D
			target_pos = p.global_position
			return

	# Senão, escolhe posição aleatória num raio em volta do start_pos
	var ang: float = rng.randf() * TAU
	var r: float = rng.randf() * roam_radius
	target_pos = start_pos + Vector2(cos(ang), sin(ang)) * r
