# items/Sword.gd
extends Item
class_name Sword

@export var damage: int = 1

func _ready() -> void:
	# define o tipo, caso esqueça no editor
	if item_type == "":
		item_type = "sword"

func on_use() -> void:
	# Aqui, mais pra frente, você vai implementar o ataque:
	# - ativar uma hitbox
	# - checar dragões
	# - etc.
	print("Espada usada! (implementar ataque aqui)")
