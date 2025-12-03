# items/Chalice.gd
extends Item
class_name Chalice


func _ready() -> void:
	if item_type == "":
		item_type = "chalice"
	if pivot_offset == Vector2.ZERO:
		pivot_offset = Vector2(14.0, -2.0)  # ajusta pra encaixar na mão se precisar


func on_use() -> void:
	# Normalmente o cálice não tem "uso ativo".
	# A vitória é checada quando o player entra na área do castelo dourado
	# carregando um item com item_type == "chalice".
	pass
