extends Node2D

var itens_proximos: Array = []
var item_carregado: Node2D = null

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("items"):
		itens_proximos.append(area)
	elif area.get_parent() and area.get_parent().is_in_group("items"):
		itens_proximos.append(area.get_parent())

func _on_area_2d_area_exited(area: Area2D):
	if area.is_in_group("items"):
		itens_proximos.erase(area)
	elif area.get_parent() and area.get_parent().is_in_group("items"):
		itens_proximos.erase(area.get_parent())

func escolher_item():
	if itens_proximos.is_empty():
		return null
	return itens_proximos[0]

func pegar_item(area: Area2D):
	if area == null:
		return

	var item := area.get_parent()

	# Se já existe item carregado → soltar primeiro
	if item_carregado:
		soltar_item(item_carregado)

	# remover do array
	itens_proximos.erase(area)

	# Desativar colisão enquando está sendo carregado
	area.monitoring = false
	area.monitorable = false

	# Mover o item totalmente para o morcego
	item.reparent(self)
	item.position = Vector2(0, 12)

	item_carregado = item
	print("Carregando:", item.name)


func soltar_item(item: Node2D):
	if item == null:
		return

	# volta o item pro mundo
	var world := get_tree().current_scene
	item.reparent(world)

	# posição onde será solto
	item.global_position = global_position + Vector2(0, 16)

	# REATIVA a colisão do Area2D
	var area := item.get_node("Area2D")
	if area:
		area.monitoring = true
		area.monitorable = true

	item_carregado = null


func _physics_process(delta):
	if item_carregado == null and not itens_proximos.is_empty():
		var alvo = escolher_item()
		if alvo:
			pegar_item(alvo)
