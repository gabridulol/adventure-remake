extends Node2D

# ---------- tuning ----------
@export var speed: float = 80.0
@export var roam_radius: float = 200.0
@export var hover_amplitude: float = 6.0
@export var hover_speed: float = 3.5
@export var reach_threshold: float = 8.0
# -----------------------------

var itens_proximos: Array = []          # sempre Area2D dos itens
var item_carregado: Node2D = null

var start_pos: Vector2
var target_pos: Vector2
var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	start_pos = global_position
	_pick_new_roam_target()

# -------------------------------------------------------------------
# DETECÇÃO DE ITENS (lista sempre com Area2D)
# -------------------------------------------------------------------
func _on_area_2d_area_entered(area: Area2D):
	# aqui assumimos que o GRUPO "items" está na Area2D do item
	# (não no Node2D raiz)
	if not area.is_in_group("items"):
		return

	if not itens_proximos.has(area):
		itens_proximos.append(area)

	# Se já está carregando um item e encostou em outro -> troca
	if item_carregado != null:
		var area_atual: Area2D = item_carregado.get_node("Area2D")
		if area_atual != area:
			pegar_item(area)


func _on_area_2d_area_exited(area: Area2D):
	if itens_proximos.has(area):
		itens_proximos.erase(area)

func escolher_item() -> Area2D:
	if itens_proximos.is_empty():
		return null
	return itens_proximos[0]

# -------------------------------------------------------------------
# PEGAR / SOLTAR ITEM
# -------------------------------------------------------------------
func pegar_item(area: Area2D):
	if area == null:
		return

	var item := area.get_parent()   # Node2D raiz do item

	# Se já existe item carregado → soltar primeiro
	if item_carregado:
		soltar_item(item_carregado)

	# remover essa área da lista de proximidade
	itens_proximos.erase(area)

	# Desativar colisão enquanto está sendo carregado
	area.monitoring = false
	area.monitorable = false

	# Mover o item para o morcego
	item.reparent(self)
	item.position = Vector2(0, 12)

	item_carregado = item
	print("Carregando:", item.name)


func soltar_item(item: Node2D):
	if item == null:
		return

	var world := get_tree().current_scene
	item.reparent(world)

	# posição onde será solto (um pouco mais longe pra não ficar colidindo de novo)
	item.global_position = global_position + Vector2(48, 0)

	# REATIVA Area2D
	if item.has_node("Area2D"):
		var area: Area2D = item.get_node("Area2D")
		area.monitoring = true
		area.monitorable = true

	item_carregado = null
# -------------------------------------------------------------------



# ----------------------- movimento / wander -----------------------
func _physics_process(delta):
	_move_toward_target(delta)

	# pegar item AUTOMÁTICO APENAS se não estiver carregando nada
	if item_carregado == null and not itens_proximos.is_empty():
		var alvo: Area2D = escolher_item()
		if alvo:
			pegar_item(alvo)


func _move_toward_target(delta):
	# hover visual
	var hover = Vector2(0, sin(Time.get_ticks_msec() / 1000.0 * hover_speed) * hover_amplitude)

	if target_pos == null:
		_pick_new_roam_target()

	var dir = (target_pos - global_position)
	if dir.length() > reach_threshold:
		var vel = dir.normalized() * speed
		global_position += vel * delta
	else:
		_pick_new_roam_target()

	# se tiver sprite, aplica hover
	if has_node("Sprite2D"):
		$Sprite2D.position = hover


func _pick_new_roam_target():
	var ang = rng.randf() * PI * 2.0
	var r = rng.randf() * roam_radius
	target_pos = start_pos + Vector2(cos(ang), sin(ang)) * r
