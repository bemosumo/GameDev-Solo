extends Area2D

var speed = 250.0
var direction = Vector2.DOWN

func _ready():
	# Sambungin sinyal otomatis pas peluru spawn
	body_entered.connect(_on_body_entered)

func _process(delta):
	global_position += direction * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# FUNGSI TABRAKAN
func _on_body_entered(body):
	if body.is_in_group("player"): 
		if body.has_method("take_damage"):
			body.take_damage(1) # Ngasih damage 1
		queue_free() # Pelurunya langsung hancur
