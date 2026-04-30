extends Area2D

@export var speed: float = 250.0
@export var damage: float = 20.0

func _ready():
	# BIKIN RINTANGAN JADI KECIL (Biar gak segede kapal)
	scale = Vector2(0.4, 0.4)

func _process(delta):
	position.y += speed * delta
	if position.y > 800:
		queue_free()

func _on_body_entered(body):
	# Kalau yang ditabrak adalah player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free() # Rintangan hancur/meledak setelah nabrak
