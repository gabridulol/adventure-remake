# items/Magnet.gd
extends Item
class_name Magnet

@export var radius: float = 160.0   # raio de alcance
@export var target_distance: float = 24.0  # distância final dos itens em relação ao player


func _ready() -> void:
	if item_type == "":
		item_type = "magnet"
	if pivot_offset == Vector2.ZERO:
		pivot_offset = Vector2(14.0, 0.0)


func on_use() -> void:
	if carried_by == null:
		return

	var player_global_pos: Vector2 = carried_by.global_position

	var nodes: Array = get_tree().get_nodes_in_group("items")
	for n in nodes:
		if n == self:
			continue
		if not (n is Item):
			continue

		var itm: Item = n as Item

		# ignora itens que já estão sendo carregados
		if itm.carried_by != null:
			continue

		var dist: float = itm.global_position.distance_to(player_global_pos)
		if dist > radius:
			continue

		# direção do item até o player
		var dir: Vector2 = (player_global_pos - itm.global_position).normalized()
		# coloca o item "perto" do player, mas não em cima
		itm.global_position = player_global_pos - dir * target_distance

	print("Ímã usado: itens próximos foram puxados.")
