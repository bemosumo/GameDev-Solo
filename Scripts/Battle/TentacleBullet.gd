extends Area2D

var speed = 180.0 # Agak lambat biar lengkungannya kelihatan cantik
var direction = Vector2.DOWN

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10) # DAMAGE SAKIT! 10 point!
		queue_free()
