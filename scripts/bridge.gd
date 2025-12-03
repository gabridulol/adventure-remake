# items/Bridge.gd
extends Item
class_name Bridge

# Ex.: em Adventure ela "estica" por cima de paredes/rios.
# Aqui você pode usar isso pra desenhar o tamanho dela no mundo.
@export var length: float = 64.0


func _ready() -> void:
	if item_type == "":
		item_type = "bridge"
	if pivot_offset == Vector2.ZERO:
		pivot_offset = Vector2(12.0, 0.0)


func on_drop() -> void:
	super.on_drop()
	# Aqui você pode ativar um grupo ou mudar colisão,
	# pra o Mundo saber que existe uma ponte neste local.
	add_to_group("bridges")
	print("Ponte posicionada no mundo.")


func on_use() -> void:
	# Em Adventure original ela não tem "uso ativo";
	# o efeito acontece pelo fato de estar posicionada em certo lugar.
	pass
