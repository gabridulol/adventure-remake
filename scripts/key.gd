# items/Key.gd
extends Item
class_name Key

@export var color: String = "yellow"  # deve bater com a cor da porta, ex: "yellow", "blue", "red"


func _ready() -> void:
	if item_type == "":
		item_type = "key"
	if pivot_offset == Vector2.ZERO:
		# geralmente uma chave é mais próxima do centro
		pivot_offset = Vector2(10.0, 0.0)


func on_use() -> void:
	# Normalmente a chave não "usa" sozinha.
	# A porta é que vai checar se o Player está carregando uma Key com a cor certa.
	pass
