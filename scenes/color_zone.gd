extends Area2D
class_name ColorZone

# Qual paleta aplicar quando o player entrar
@export_range(0, 6) var palette_index: int = 0

# Se quiser que ao sair da área ele volte para uma paleta padrão
@export var reset_on_exit: bool = false
@export_range(0, 6) var default_palette_on_exit: int = 0

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p := body as Player
		p.set_palette(palette_index)


func _on_body_exited(body: Node2D) -> void:
	if not reset_on_exit:
		return

	if body is Player:
		var p := body as Player
		p.set_palette(default_palette_on_exit)
