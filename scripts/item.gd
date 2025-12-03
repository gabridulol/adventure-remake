# items/Item.gd
extends Area2D
class_name Item

# Ex: "sword", "key", "chalice", "bridge", "magnet"
@export var item_type: String = ""
@export var can_be_carried: bool = true

# Posição relativa ao ItemPivot do player quando estiver na mão
@export var pivot_offset: Vector2 = Vector2(16.0, 0.0)

var carried_by: Node = null


func on_pickup(by: Node) -> void:
	carried_by = by
	# Se o item precisar fazer algo especial ao ser pego, você sobrescreve isso na subclasse.


func on_drop() -> void:
	carried_by = null
	# Se o item precisar resetar estado ao cair no chão, sobrescreve aqui.


func on_use() -> void:
	# Default: não faz nada.
	# Espada, por exemplo, vai sobrescrever isso pra atacar.
	pass
