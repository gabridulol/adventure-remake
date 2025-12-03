extends Camera2D

@export var target_path: NodePath
@export var zoom_level: float = 2.5

var target: Node2D = null

func _ready() -> void:
	# define o zoom fixo
	zoom = Vector2(zoom_level, zoom_level)

	if target_path != NodePath(""):
		target = get_node(target_path) as Node2D


func _process(delta: float) -> void:
	if target != null:
		global_position = target.global_position
