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
	# Subclasses podem sobrescrever, mas sempre chamando `super.on_pickup(by)` se precisar.


func on_drop() -> void:
	carried_by = null
	# Subclasses podem sobrescrever se precisarem resetar algo.


func on_use() -> void:
	# Default: não faz nada.
	pass
