extends Area2D
class_name VictoryZone


func _on_player_won() -> void:
	print("VITÓRIA! Cálice entregue no castelo dourado.")
	# Por enquanto: fecha o jogo
	get_tree().quit()

	# Depois você pode trocar por:
	# get_tree().change_scene_to_file("res://ui/VictoryScreen.tscn")


func _on_body_entered(body: Node2D) -> void:
	# Só nos importamos com o Player
	if not (body is Player):
		return

	var player := body as Player

	# Se não está carregando nada, não faz nada
	if player.carried_item == null:
		print("Player entrou na VictoryZone sem item.")
		return

	# Verifica se o item carregado é um Item e se é o cálice
	if player.carried_item is Item:
		var item := player.carried_item as Item
		print("Player entrou na VictoryZone com item_type =", item.item_type)
		if item.item_type == "chalice":
			_on_player_won()
	else:
		print("carried_item não é um Item: ", player.carried_item)
