# items/Sword.gd
extends Item
class_name Sword

@export var damage: int = 1
@export var attack_arc_deg: float = 90.0  # só pra futura lógica de ataque
@export var attack_cooldown: float = 0.3

var _last_attack_time: float = -999.0


func _ready() -> void:
	if item_type == "":
		item_type = "sword"
	# ajuste inicial padrão; você pode sobrescrever no Inspector
	if pivot_offset == Vector2.ZERO:
		pivot_offset = Vector2(16.0, 0.0)


func on_use() -> void:
	if carried_by == null:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_attack_time < attack_cooldown:
		return  # ainda em cooldown

	_last_attack_time = now

	# Aqui entra a lógica real de ataque (hitbox, checar dragões, etc.)
	print("Espada usada! (TODO: implementar ataque de verdade)")
