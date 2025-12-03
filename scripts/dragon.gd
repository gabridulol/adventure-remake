extends CharacterBody2D

enum State { IDLE, CHASING, DEAD }
var state: State = State.IDLE

@export var speed: float = 60.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_area: Area2D = $VisionArea
@onready var hitbox: Area2D = $Hitbox

var target: CharacterBody2D = null


func _ready() -> void:
	# animação inicial
	if anim:
		anim.play("dragon_red") # ajusta pro nome da sua animação

	# visão para perseguir o player
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)

	# hitbox para causar dano / receber dano
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO

		State.CHASING:
			if target and is_instance_valid(target):
				var direction: Vector2 = (target.global_position - global_position).normalized()
				velocity = direction * speed
			else:
				velocity = Vector2.ZERO
				state = State.IDLE

		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()


# ==========================
#   VISÃO (perseguir player)
# ==========================
func _on_vision_body_entered(body: Node) -> void:
	if body.is_in_group("player") and state != State.DEAD:
		target = body as CharacterBody2D
		state = State.CHASING


func _on_vision_body_exited(body: Node) -> void:
	if body == target:
		target = null
		state = State.IDLE


# ==========================
#   HITBOX (colisão real)
# ==========================
# Player encostou no corpo do dragão → player morre (se dragão vivo)
func _on_hitbox_body_entered(body: Node2D) -> void:
	if state == State.DEAD:
		return

	if body.is_in_group("player"):
		var player := body as Player
		player.die()  # vamos criar esse método no Player
		# Adventure original normalmente deixa o dragão vivo;
		# se quiser matar os dois, pode chamar die() aqui também.


# Espada (item) encostou no dragão → dragão morre
func _on_hitbox_area_entered(area: Area2D) -> void:
	if state == State.DEAD:
		return

	# Só queremos itens
	if not area.is_in_group("itens"):
		return

	# Checa se o item é uma espada
	var item_node := area as Node
	if item_node is Sword:
		die()


func die() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD

	# Troca animação (ajusta pro nome que você tiver)
	if anim:
		anim.play("dragon_red_dead")
		#anim.stop()

	# Desativa hitbox pra não causar mais dano
	hitbox.monitoring = false
	hitbox.monitorable = false

	# Opcional: sair do grupo "enemy" ou "dragon", se estiver usando
	# remove_from_group("dragon")
