extends Area2D
class_name TeleportZone

# Para onde o player vai ser teleportado
@export var target_spawn_path: NodePath
# opcional: se você quer dar um pequeno offset extra
@export var offset: Vector2 = Vector2.ZERO


func _on_TeleportZone_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return

	var player := body as Player

	# pega o nodo de destino
	var target_node := get_node_or_null(target_spawn_path)
	if target_node == null or not (target_node is Node2D):
		push_warning("TeleportZone sem destino válido.")
		return

	var target_pos := (target_node as Node2D).global_position + offset

	# zera movimento e teleporta
	player.velocity = Vector2.ZERO
	player.global_position = target_pos
